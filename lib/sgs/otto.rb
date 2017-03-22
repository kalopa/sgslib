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
# Routines for interfacing with the low-level microcontroller.
#
module SGS
  class Otto < RedisBase
    attr_reader :rudder, :sail, :compass, :twa
    attr_accessor :bvcal, :bical, :btcal, :svcal

    def initialize
      @bvcal = 0.0
      @bical = 0.0
      @btcal = 0.0
      @svcal = 0.0
      @rudder = read_rudder
      @sail = read_sail
      @compass = read_compass
      @twa = read_twa
      super
    end

    #
    # Set the required rudder angle. Input values range from +/- 40 degrees
    def rudder=(val)
      val = -39.9 if val < -39.9
      val = 39.9 if val > 39.9
      return if @rudder == val
      @rudder = val
      intval = (@rudder * 120.0 / 40.0).to_int + 128
      puts "New rudder value: #{intval} (#{@rudder} degrees)"
      send_command(SET_RUDDER, intval)
    end

    #
    # Set the required sail angle. Input values range from 0 -> 90 degrees.
    def sail=(val)
      val = 0.0 if val < 0.0
      val = 90.0 if val > 90.0
      return if @sail == val
      @sail = val
      intval = (@sail * 256.0 / 90.0).to_int
      puts "New sail angle: #{intval} (#{@sail} degrees)"
      send_command(SET_SAIL, intval)
    end

    #
    # Set the required compass reading. Input values range from 0 -> 359 degrees
    def compass=(val)
      while val < 0.0
        val += 360.0
      end
      val %= 360.0
      return if @compass == val
      @compass = val
      intval = (@compass * 256.0 / 360.0).to_int
      puts "New compass heading: #{intval} (#{@compass} degrees)"
      send_command(SET_COMPASS, intval)
    end

    #
    # Set the required true wind angle. Input values range from +/- 180 degrees
    def twa=(val)
      val = -179.9 if val < -179.9
      val = 179.9 if val > 179.9
      return if @twa == val
      @twa = val
      val = 360.0 + val if val < 0.0
      intval = (val * 256.0 / 360.0).to_int
      puts "New TWA: #{intval} (#{@twa} degrees)"
      send_command(SET_TWA, intval)
    end

    #
    # Read the uptime clock
    def read_uptime
      intval = send_command(READ_UPTIME)
    end

    #
    # Read the battery voltage
    def read_battery_volts
      intval = send_command(READ_BATTERY_VOLTAGE)
      intval.to_f * @bvcal / 1024.0
    end

    #
    # Read the battery current
    def read_battery_current
      intval = send_command(READ_BATTERY_CURRENT)
      intval.to_f * @bical / 1024.0
    end

    #
    # Read the boat temperature
    def read_boat_temperature
      intval = send_command(READ_BOAT_TEMPERATURE)
      intval.to_f * @btcal / 1024.0
    end

    #
    # Read the solar voltage
    def read_solar_volts
      intval = send_command(READ_SOLAR_VOLTAGE)
      intval.to_f * @svcal / 1024.0
    end

    #
    # Read the actual compass value
    def read_compass
      intval = send_command(GET_COMPASS)
      intval.to_f * 360.0 / 256.0
    end

    #
    # Read the actual TWA value
    def read_twa
      intval = send_command(GET_TWA)
      val = intval.to_f * 180.0 / 128.0
      val = val - 360.0 if val > 180.0
      val
    end

    #
    # Read the actual boat pitch
    def read_pitch
      intval = send_command(GET_PITCH)
      intval.to_f
    end

    #
    # Read the actual boat heel
    def read_heel
      intval = send_command(GET_HEEL)
      intval.to_f
    end
  end
end
