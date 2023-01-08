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

##
# Routines for interfacing with the low-level microcontroller.
#
module SGS
  class Otto < RedisBase
    attr_accessor :raw_rudder, :raw_sail, :raw_compass, :raw_awa, :raw_tc, :raw_ta
    attr_accessor :mode, :rudder_m, :rudder_c, :sail_m, :sail_c
    attr_accessor :bv_m, :bv_c, :bi_m, :bi_c, :bt_m, :bt_c, :sv_m, :sv_c

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
      # Set up some basic parameters for battery/solar readings
      @bv_m = @bi_m = @bt_m = @sv_m = 1.0
      @bv_c = @bi_c = @bt_c = @sv_c = 0.0
      super
    end

    #
    # Main daemon function (called from executable)
    def self.daemon
      loop do
        sleep 300
      end
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
