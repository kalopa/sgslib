#
# Copyright (c) 2013, Kalopa Research.  All rights reserved.  This is free
# software; you can redistribute it and/or modify it under the terms of the
# GNU General Public License as published by the Free Software Foundation;
# either version 2, or (at your option) any later version.
#
# It is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with this product; see the file COPYING.  If not, write to the Free
# Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.
#
# THIS SOFTWARE IS PROVIDED BY KALOPA RESEARCH "AS IS" AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
# OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
# IN NO EVENT SHALL KALOPA RESEARCH BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF
# USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

##
# Routines for handling sailboat alarms. Note that this is the definitive
# list of alarms on the system. To add or modify an alarm, do so here.
#
module SGS
  ##
  # Deal with command subsystem.
  #
  # This code handles the Fonz packet commands.
  #
  class Command < RedisBase
    attr_accessor :last_received, :time

    FONZ_PING = 0
    FONZ_MAGIC = 1
    FONZ_ACK = 2

    FONZ_GET_TIMEL = 4
    FONZ_TIME_DATAL = 5
    FONZ_GET_TIMEH = 6
    FONZ_TIME_DATAH = 7

    FONZ_GET_VOLTS1 = 8
    FONZ_VOLTS1_DATA = 9
    FONZ_GET_VOLTS2 = 10
    FONZ_VOLTS2_DATA = 11
    FONZ_GET_VOLTS3 = 12
    FONZ_VOLTS3_DATA = 13
    FONZ_GET_VOLTS4 = 14
    FONZ_VOLTS4_DATA = 15
    FONZ_GET_VOLTS5 = 16
    FONZ_VOLTS5_DATA = 17
    FONZ_GET_VOLTS6 = 18
    FONZ_VOLTS6_DATA = 19
    FONZ_GET_VOLTS7 = 20
    FONZ_VOLTS7_DATA = 21
    FONZ_GET_VOLTS8 = 22
    FONZ_VOLTS8_DATA = 23

    FONZ_GET_CURR1 = 24
    FONZ_CURR1_DATA = 25
    FONZ_GET_CURR2 = 26
    FONZ_CURR2_DATA = 27
    FONZ_GET_CURR3 = 28
    FONZ_CURR3_DATA = 29
    FONZ_GET_CURR4 = 30
    FONZ_CURR4_DATA = 31
    FONZ_GET_CURR5 = 32
    FONZ_CURR5_DATA = 33
    FONZ_GET_CURR6 = 34
    FONZ_CURR6_DATA = 35
    FONZ_GET_CURR7 = 36
    FONZ_CURR7_DATA = 37
    FONZ_GET_CURR8 = 38
    FONZ_CURR8_DATA = 39

    FONZ_GET_ALARMS = 40
    FONZ_ALARM_RAISE = 41

    FONZ_GET_OTTORST = 42
    FONZ_OTTORST_DATA = 43
    FONZ_GET_MISSION = 44
    FONZ_MISSION_DATA = 45
    FONZ_GET_COMPASS = 46
    FONZ_COMPASS_DATA = 47
    FONZ_GET_TWA = 48
    FONZ_TWA_DATA = 49
    FONZ_GET_RUDDER = 50
    FONZ_RUDDER_DATA = 51
    FONZ_GET_SAIL = 52
    FONZ_SAIL_DATA = 53
    FONZ_GET_PDOWN = 54
    FONZ_PDOWN_DATA = 55
    FONZ_GET_NAVLIGHT = 56
    FONZ_NAVLIGHT_DATA = 57
    FONZ_GET_BUZZER = 58
    FONZ_BUZZER_DATA = 59

    FONZ_GET_EEADDR = 60
    FONZ_SET_EEADDR = 61
    FONZ_GET_EEDATA = 62
    FONZ_SET_EEDATA = 63

    MESSAGES = [
      "Ping", "Magic Word",
      "ACK", "??",
      "Get Time (Lo)", "Time Data (Lo)",
      "Get Time (Hi)", "Time Data (Hi)",
      "Get Voltage1", "Voltage1 Data",
      "Get Voltage2", "Voltage2 Data",
      "Get Voltage3", "Voltage3 Data",
      "Get Voltage4", "Voltage4 Data",
      "Get Voltage5", "Voltage5 Data",
      "Get Voltage6", "Voltage6 Data",
      "Get Voltage7", "Voltage7 Data",
      "Get Voltage8", "Voltage8 Data",
      "Get Current1", "Current1 Data",
      "Get Current2", "Current2 Data",
      "Get Current3", "Current3 Data",
      "Get Current4", "Current4 Data",
      "Get Current5", "Current5 Data",
      "Get Current6", "Current6 Data",
      "Get Current7", "Current7 Data",
      "Get Current8", "Current8 Data",
      "Get Alarms", "Alarm Raised!",
      "Get Otto Reset", "Otto Reset Status",
      "Get Mission", "Mission Data",
      "Get Compass", "Compass Data",
      "Get TWA", "TWA Data",
      "Get Rudder Position", "Rudder Position Data",
      "Get Sail Trim", "Sail Trim Data",
      "Get Power Down", "Time to Power Down",
      "Get Nav Light", "Nav Light Status",
      "Get Buzzer", "Buzzer Status",
      "Get EEPROM Address", "Set EEPROM Address",
      "Get EEPROM Data", "Set EEPROM Data"
    ].freeze

    def initialize
      @count = 0
      @last_report = nil
      @time = Array.new(32, Time.at(0))
      super
    end

    #
    # Convert a command code into a string.
    def name(code)
      (code < MESSAGES.count) ? MESSAGES[code] : nil
    end

    #
    # Send a command to the microcontroller
    def send_command(cmd, arg = nil)
      puts "Send command #{cmd} (#{name(cmd)})"
      puts "Arg is #{arg}" if arg
      return 0
    end
  end
end
