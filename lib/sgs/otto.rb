#
# Copyright (c) 2013-2023, Kalopa Robotics Limited.  All rights
# reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2 of
# the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
# 02110-1301, USA.
#
# THIS SOFTWARE IS PROVIDED BY KALOPA ROBOTICS LIMITED "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
# TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
# PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL KALOPA
# ROBOTICS LIMITED BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
# OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# ABSTRACT
# This daemon handles all serial I/O with the low-level board (Otto). Otto
# publishes various status messages at regular intervals, and has a series
# of registers which can be used to alter the low-level operational state.
# This daemon code has two threads. One thread listens for RPCs to update
# Otto register state, and the other listens for status messages from Otto.
# The class also has helper functions for converting between Otto data
# formats (usually 8bit) and internal formats (usually floating point).
#
require 'serialport'
require 'msgpack'

##
# Routines for interfacing with the low-level microcontroller.
#
module SGS
  class Otto < RedisBase
    attr_accessor :mode, :serial_port
    attr_accessor :bv_m, :bv_c, :bi_m, :bi_c, :bt_m, :bt_c, :sv_m, :sv_c
    attr_reader :alarm_status
    attr_reader :actual_rudder, :actual_sail
    attr_reader :otto_mode, :otto_timestamp, :telemetry

    #
    # Updates to Otto are done by setting an 8bit register value, as below.
    ALARM_CLEAR_REGISTER = 0
    MISSION_CONTROL_REGISTER = 1
    MODE_REGISTER = 2
    BUZZER_REGISTER = 3
    RUDDER_ANGLE_REGISTER = 4
    SAIL_ANGLE_REGISTER = 5
    COMPASS_HEADING_REGISTER = 6
    MIN_COMPASS_REGISTER = 7
    MAX_COMPASS_REGISTER =8
    AWA_HEADING_REGISTER = 9
    MIN_AWA_REGISTER = 10
    MAX_AWA_REGISTER = 11
    WAKE_DURATION_REGISTER = 12
    NEXT_WAKEUP_REGISTER = 13
    RUDDER_PID_P = 14
    RUDDER_PID_I = 15
    RUDDER_PID_D = 16
    RUDDER_PID_E_NUM = 17
    RUDDER_PID_E_DEN = 18
    RUDDER_PID_U_DIV = 19
    SAIL_MXC_M_VALUE = 20
    SAIL_MXC_C_VALUE = 21
    SAIL_MXC_U_DIV = 22
    MAX_REGISTER = 23

    #
    # This is different from mission mode. This mode defines how Otto should
    # operate. Inert means "do nothing". Diagnostic mode is for the low-level
    # code to run self-checks and calibrations. Manual means that the upper
    # level system controls the rudder and sail angle without any higher-level
    # PID controller. Track compass means that the boat will try to keep the
    # actual compass reading within certain parameters, and track AWA will
    # try to maintain a specific "apparent wind angle".
    MODE_INERT = 0
    MODE_DIAG = 1
    MODE_MANUAL = 2
    MODE_REMOTE = 3
    MODE_TRACK_COMPASS = 4
    MODE_TRACK_AWA = 5

    #
    # Define some tweaks for rudder and sail setting. Rudder goes from
    # +/-40 degrees, with zero indicating a straight rudder. On Otto, this
    # translates to 0 (for -40.0), 128 (for the zero position) and 255 (for
    # +40 degrees of rudder). A fully trimmed-in sail is zero and a fully
    # extended sail is 255 (0->100 from a function perspective).
    RUDDER_MAX = 40.0
    RUDDER_MIN = -40.0
    RUDDER_M = 3.175
    RUDDER_C = 128.0
    SAIL_MAX = 100.0
    SAIL_MIN = 0.0
    SAIL_M = 2.55
    SAIL_C = 0.0

    #
    # Set up some useful defaults. We assume rudder goes from 0 to 255 as does
    # the sail angle. 
    def initialize
      serial_port = nil
      #
      # Set some defaults for the read-back parameters
      # The following five parameters are reported back by Otto with a status
      # message, and are read-only. @alarm_status is 16 bits while the other
      # four are 8-bit values. The helper methods convert these 8-bit values
      # into radians, etc. The telemetry parameters are used to capture
      # telemetry data from Otto.
      @alarm_status = 0
      @actual_rudder = @actual_sail = @actual_awa = @actual_compass = 0
      @telemetry = Array.new(16)
      #
      # Mode is used by Otto to decide how to steer the boat and trim the
      # sails.
      @otto_mode = MODE_INERT
      @otto_timestamp = 1000
      #
      # Set up some basic parameters for battery/solar readings
      @bv_m = @bi_m = @bt_m = @sv_m = 1.0
      @bv_c = @bi_c = @bt_c = @sv_c = 0.0
      #
      # RPC client / server
      @rpc_client = @rpc_server = nil
      super
    end

    #
    # Main daemon function (called from executable). The job of
    # this daemon is to accept commands from the Redis pub/sub
    # stream and send them to the low-level device, recording the
    # response and sending it back to the caller. Note that we need
    # to do an initial sync with the device as it will ignore the
    # usual serial console boot-up gumph awaiting our sync message.
    def self.daemon
      puts "Low-level (Otto) communication subsystem starting up..."
      otto = new
      config = Config.load
      otto.serial_port = SerialPort.new config.otto_device, config.otto_speed
      otto.serial_port.read_timeout = 10000
      #
      # Start by getting a sync message from Otto.
      otto.synchronize()
      #
      # Run the communications service with Otto. Two threads are used, one for
      # reading and one for writing. Don't let the command stack get too big.
      t1 = Thread.new { otto.reader_thread }
      t2 = Thread.new { otto.writer_thread }
      t1.join
      t2.join
    end

    #
    # Build a C include file based on the current register definitions
    def self.build_include(fname)
      otto = new
      File.open(fname, "w") do |f|
        f.puts "/*\n * Autogenerated by #{__FILE__}.\n * DO NOT HAND-EDIT!\n */"
        constants.sort.each do |c|
          if c.to_s =~ /REGISTER$/
            cval = Otto.const_get(c)
            str = "#define SGS_#{c.to_s}"
            str += "\t" if str.length < 32
            str += "\t#{cval}"
            f.puts str
          end
        end
      end
    end

    #
    # Synchronize with the low-level board by sending CQ messages until
    # they respond. When Mother boots up, the serial console is shared with
    # Otto so a lot of rubbish is sent to the low-level board. To notify
    # Otto that we are now talking sense, we send @@CQ! and Otto responds
    # with +CQOK. Note that this function, which is always called before any
    # of the threads, is bidirectional in terms of serial I/O.
    def synchronize
      index = 0
      backoffs = [1, 1, 1, 1, 2, 2, 3, 5, 10, 10, 20, 30, 60]
      puts "Attempting to synchronize with Otto..."
      while true do
        begin
          @serial_port.puts "@@CQ!"
          resp = read_data
          break if resp =~ /^\+CQOK/ or resp =~ /^\+OK/
          sleep backoffs[index]
          index += 1 if index < (backoffs.count - 1)
        end
      end
      puts "Synchronization complete!"
    end

    #
    # Thread to read status messages from Otto and handle them
    def reader_thread
      puts "Starting OTTO reader thread..."
      while true
        data = read_data
        next if data.nil? or data.length == 0
        case data[0]
        when '$'
          #
          # Status message (every second)
          parse_status(data[1..])
        when '@'
          #
          # Otto elapsed time (every four seconds)
          parse_tstamp(data[1..])
        when '!'
          #
          # Otto mode state (every four seconds)
          parse_mode(data[1..])
        when '>'
          #
          # Telemetry data (every two seconds)
          parse_telemetry(data[1..])
        when '*'
          #
          # Message for the debug log
          parse_debug(data[1..])
        end
      end
    end

    #
    # Thread to write commands direct to Otto.
    def writer_thread
      puts "Starting OTTO writer thread..."
      #
      # Now listen for Redis PUB/SUB requests and act on each one.
      myredis = Redis.new
      while true
        channel, request = myredis.brpop("otto")
        request = MessagePack.unpack(request)
        puts "Req:[#{request.inspect}]"
        params = request['params']
        next if request['method'] != "set_local_register"
        puts "PARAMS: #{params}"
        cmd = "R%d=%X\r\n" % params
        puts "Command: #{cmd}"
        @serial_port.write cmd
        puts "> Sending command: #{str}"
        @serial_port.puts "#{str}"
      end
    end

    #
    # Read data from the serial port
    def read_data
      begin
        data = @serial_port.readline.chomp
      rescue EOFError => error
        puts "Otto Read Timeout!"
        data = nil
      end
      data
    end

    #
    # Parse a status message from Otto. In the form:
    # 0001:C000:0000
    def parse_status(status)
      puts "OTTO PARSE: #{status}"
      args = status.split /:/
      @alarm_status = args[0].to_i(16)
      wc = args[1].to_i(16)
      rs = args[2].to_i(16)
      @actual_awa = (wc >> 8) & 0xff
      @actual_compass = (wc & 0xff)
      @actual_rudder = (rs >> 8) & 0xff
      @actual_sail = (rs & 0xff)
      p self
      self.save_and_publish
    end

    #
    # Parse a timestamp message from Otto. In the form: "000FE2" 24 bits
    # representing the elapsed seconds since Otto restarted.
    def parse_tstamp(tstamp)
      newval = tstamp.to_i(16)
      if newval < @otto_timestamp
        puts "ALARM! Otto rebooted (or something)..."
      end
      @otto_timestamp = newval
    end

    #
    # Parse a mode state message from Otto. In the form: "00". An eight bit
    # quantity.
    def parse_mode(mode)
      @otto_mode = mode.to_i(16)
    end

    #
    # Parse a telemetry message from Otto. In the form: "7327" where the first
    # character is the channel (0->9) and the remaining 12 bits are the value.
    def parse_telemetry(telemetry)
      data = telemetry.to_i(16)
      chan = (data >> 12) & 0xf
      @telemetry[chan] = data & 0xfff
    end

    #
    # Parse a debug message from the low-level code. Basically just append it
    # to a log file.
    def parse_debug(debug_data)
      puts "DEBUG: [#{debug_data}].\n"
    end

    #
    # Clear an alarm setting
    def alarm_clear(alarm)
      set_register(ALARM_CLEAR_REGISTER, alarm)
    end

    #
    # Set the Otto mode
    def mode=(val)
      set_register(MODE_REGISTER, val) if @otto_mode != val
    end

    #
    # Set the required rudder angle. Input values range from +/- 40.0 degrees
    def rudder=(val)
      val = RUDDER_MIN if val < RUDDER_MIN
      val = RUDDER_MAX if val > RUDDER_MAX
      val = (RUDDER_M * val.to_f + RUDDER_C).to_i
      if val != @actual_rudder
        @actual_rudder = val
        set_register(RUDDER_ANGLE_REGISTER, val)
      end
      mode = MODE_MANUAL
    end

    #
    # Return the rudder angle in degrees
    def rudder
      (@actual_rudder.to_f - RUDDER_C) / RUDDER_M
    end

    #
    # Set the required sail angle. Input values range from 0 -> 100.
    def sail=(val)
      val = SAIL_MIN if val < SAIL_MIN
      val = SAIL_MAX if val > SAIL_MAX
      val = (SAIL_M * val.to_f + SAIL_C).to_i
      if val != @actual_sail
        @actual_sail = val
        set_register(SAIL_ANGLE_REGISTER, val)
      end
      mode = MODE_MANUAL
    end

    #
    # Return the sail setting (0.0 -> 100.0)
    def sail
      (@actual_sail.to_f - SAIL_C) / SAIL_M
    end

    #
    # Return the compass angle (in radians)
    def compass
      Bearing.xtor(@actual_compass)
    end

    #
    # Return the apparent wind angle (in radians)
    def awa
      @actual_awa -= 256 if @actual_awa > 128
      Bearing.xtor(@actual_awa)
    end

    #
    # Return the actual wind direction (in radians)
    def wind
      Bearing.xtor(@actual_compass + @actual_awa)
    end

    #
    # Set the required compass reading (in radians)
    def track_compass=(val)
      val = Bearing.rtox(val)
      if @track_compass.nil? or @track_compass != val
        @track_compass = val
        set_register(COMPASS_HEADING_REGISTER, val)
      end
      mode = MODE_TRACK_COMPASS
    end

    #
    # Return the compass value for tracking.
    def track_compass
      Bearing.xtor(@track_compass)
    end

    #
    # Set the required AWA for tracking (in radians).
    def track_awa=(val)
      val = Bearing.rtox(val)
      if @track_awa.nil? or @track_awa != val
        @track_awa = val
        set_register(AWA_HEADING_REGISTER, val)
      end
      mode = MODE_TRACK_AWA
    end

    #
    # Return the current tracking AWA (in radians).
    def track_awa
      Bearing.xtor(@track_awa)
    end

    #
    # RPC client call to set register - sent to writer function above
    def set_register(regno, value)
      @rpc_client = RPCClient.new("otto") unless @rpc_client
      @rpc_client.set_local_register(regno, value)
    end
  end
end
