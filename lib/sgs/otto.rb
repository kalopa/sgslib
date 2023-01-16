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
#
require 'serialport'
require 'msgpack'

##
# Routines for interfacing with the low-level microcontroller.
#
module SGS
  class Otto < RedisBase
    attr_accessor :raw_rudder, :raw_sail, :raw_compass, :raw_awa, :raw_tc, :raw_ta
    attr_accessor :mode, :rudder_m, :rudder_c, :sail_m, :sail_c
    attr_accessor :bv_m, :bv_c, :bi_m, :bi_c, :bt_m, :bt_c, :sv_m, :sv_c
    attr_accessor :serial_port
    attr_reader :alarm_status, :wind, :compass, :actual_rudder, :actual_sail
    attr_reader :otto_mode, :otto_timestamp, :telemetry

    MODE_INERT = 0
    MODE_DIAGNOSTICS = 1
    MODE_MANUAL = 2
    MODE_TRACK_COMPASS = 3
    MODE_TRACK_AWA = 4

    MODE_NAMES = [
      "Inert Mode", "Diagnostics Mode", "Manual Control Mode",
      "Compass-Tracking Mode", "AWA-Tracking Mode"
    ].freeze

    #
    # Set up some useful defaults. We assume rudder goes from 0 to 200 as does
    # the sail angle.
    def initialize
      serial_port = nil
      #
      # Configure the Mx + C values for sail and rudder
      @rudder_m = 2.5
      @rudder_c = 100.0
      @sail_m = 2.0
      @sail_c = 0.0
      #
      # Now set the rudder and sail to default positions (rudder is centered)
      rudder = 0.0
      sail = 0.0
      #
      # Set some defaults for the read-back parameters
      @alarm_status = @wind = @compass = @actual_rudder = @actual_sail = 0
      @otto_mode = 0
      @otto_timestamp = 1000
      @telemetry = Array.new(16)
      #
      # Set up some basic parameters for battery/solar readings
      @bv_m = @bi_m = @bt_m = @sv_m = 1.0
      @bv_c = @bi_c = @bt_c = @sv_c = 0.0
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
      config = SGS::Config.load
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
    # Synchronize with the low-level board by sending CQ messages until
    # they respond.
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
        end
      end
    end

    #
    # Thread to write commands direct to Otto.
    def writer_thread
      puts "Starting OTTO writer thread..."
      #
      # Now listen for Redis PUB/SUB requests and act on each one.
      while true
        channel, request = SGS::RedisBase.redis.brpop("otto")
        request = MessagePack.unpack(request)
        puts "Req:[#{request.inspect}]"
        cmd = {
          id: request['id'],
          args: request['params'].unshift(request['method'])
        }
        puts "CMD:#{cmd.inspect}"
        #
        # Don't let the command stack get too big.
        while @command_stack.length > 5
          sleep 5
        end

        puts "> Sending command: #{str}"
        @serial_port.puts "#{str}"

        reply = {
          'id' => id,
          'jsonrpc' => '2.0',
          'result' => result
        }
        SGS::RedisBase.redis.rpush(id, MessagePack.pack(reply))
        SGS::RedisBase.redis.expire(id, 30)
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
      puts "Parse status: #{status}"
      args = status.split /:/
      @alarm_status = args[0].to_i(16)
      wc = args[1].to_i(16)
      rs = args[2].to_i(16)
      @wind = (wc >> 8) & 0xff
      @compass = (wc & 0xff)
      @actual_rudder = (rs >> 8) & 0xff
      @actual_sail = (rs & 0xff)
      p self
      self.save_and_publish
    end

    #
    # Parse a timestamp message from Otto. In the form: "000FE2" 24 bits
    # representing the elapsed seconds since Otto restarted.
    def parse_tstamp(tstamp)
      puts "Parse timestamp: #{tstamp}"
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
      puts "Parse Otto Mode State: #{mode}"
      @otto_mode = mode.to_i(16)
    end

    #
    # Parse a telemetry message from Otto. In the form: "7327" where the first
    # character is the channel (0->9) and the remaining 12 bits are the value.
    def parse_telemetry(telemetry)
      puts "Parse Otto Telemetry Data: #{telemetry}"
      data = telemetry.to_i(16)
      chan = (data >> 12) & 0xf
      @telemetry[chan] = data & 0xff
    end

    #
    # Set the required rudder angle. Input values range from +/- 40.0 degrees
    def rudder=(val)
      val = -40.0 if val < -40.0
      val = 40.0 if val > 40.0
      @raw_rudder = (@rudder_m * val.to_f + @rudder_c).to_i
    end

    #
    # Return the rudder angle in degrees
    def rudder
      (@raw_rudder.to_f - @rudder_c) / @rudder_m
    end

    #
    # Set the required sail angle. Input values range from 0 -> 90 degrees.
    def sail=(val)
      val = 0.0 if val < 0.0
      val = 100.0 if val > 100.0
      @raw_sail = (@sail_m * val.to_f + @sail_c).to_i
    end

    #
    # Return the sail setting (0.0 -> 100.0)
    def sail
      (@raw_sail.to_f - @sail_c) / @sail_m
    end

    #
    # Return the compass angle (in radians)
    def compass
      @raw_compass.to_f * Math::PI / 128.0
    end

    #
    # Return the apparent wind angle (in radians)
    def awa
      @raw_awa.to_f * Math::PI / 128.0
    end

    #
    # Set the required compass reading. Input values range from 0 -> 359 degrees
    def track_compass=(val)
      while val < 0.0
        val += 360.0
      end
      val %= 360.0
      @raw_tc = (val.to_f * 128.0 / Math::PI).to_i
    end

    #
    # Return the compass value for tracking.
    def track_compass
      @raw_tc.to_f * Math::PI / 128.0
    end

    #
    # Set the required AWA for tracking.
    def track_awa=(val)
      val = -180.0 if val < -180.0
      val = 180.0 if val > 180.0
      @raw_ta = (val.to_f * 128.0 / Math::PI).to_i
    end

    #
    # Return the current tracking AWA.
    def track_awa
      @raw_ta.to_f * Math::PI / 128.0
    end
  end
end
