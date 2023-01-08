#
# Copyright (c) 2013-2022, Kalopa Robotics Limited.  All rights
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
# Routines for handling sailboat navigation and route planning.
#
# The code on this page was derived from formulae on the Movable Type site:
# http://www.movable-type.co.uk/scripts/latlong.html
#
module SGS
  ##
  #
  # A class to handle the course sailed, as well as polar speed calculations.
  # For speed calculations, it takes a range of polars as polynomials and
  # then applies them.
  class Course
    attr_reader :awa, :speed
    attr_writer :polar_curve

    TACK_NAME = ["Starboard", "Port"].freeze
    STARBOARD = 0
    PORT = 1

    #
    # Right now, we have one polar - from a Catalina 22.
    # Note that the speed is the same, regardless of the tack.
    STANDARD = [
       -3.15994,
       23.8741,
      -27.4595,
       16.4868,
       -5.15663,
        0.743936,
       -0.0344716
    ].freeze

    #
    # Set up the default values
    def initialize(wind = nil)
      @polar_curve = STANDARD
      @awa = 0.0
      @speed = 0.0
      @wind = wind || Bearing.new(0.0, 10.0)
      @heading = nil
      self.heading = 0
    end

    #
    # Return the current heading
    def heading
      @heading
    end

    #
    # Return the heading in degrees
    def heading_d
      Bearing.rtod @heading
    end

    #
    # Return the wind direction/speed
    def wind
      @wind
    end

    #
    # Return the Apparent Wind Angle (AWA) in degrees
    def awa_d
      Bearing.rtod @awa
    end

    #
    # Return the current tack
    def tack
      (@awa and @awa < 0.0) ? PORT : STARBOARD
    end

    #
    # Return the tack name
    def tack_name
      TACK_NAME[tack]
    end

    #
    # Set the heading
    def heading=(new_heading)
      return if @heading and @heading == new_heading
      if new_heading > 2*Math::PI
        new_heading -= 2*Math::PI
      elsif new_heading < 0.0
        new_heading += 2*Math::PI
      end
      @heading = new_heading
      self.awa = @wind.angle - @heading
    end

    #
    # Set the wind direction and recompute the AWA if appropriate. Note
    # that we don't care about wind speed (for now)
    def wind=(new_wind)
      return if @wind and @wind.angle == new_wind.angle
      @wind = new_wind
      self.awa = @wind.angle - @heading
    end

    #
    # Calculate the AWA based on our heading and wind direction
    def awa=(new_awa)
      if new_awa < -Math::PI
        new_awa += 2*Math::PI
      elsif new_awa > Math::PI
        new_awa -= 2*Math::PI
      end
      return if @awa == new_awa
      @awa = new_awa
      compute_speed
    end

    #
    # Compute a relative VMG based on the waypoint
    def relative_vmg(waypt)
      relvmg = @speed * Math::cos(waypt.bearing.angle - @heading) / waypt.distance
      puts "Relative VMG to WPT: #{waypt.name} is #{relvmg}"
      relvmg
    end

    #
    # Compute the hull speed from the polar. This is just a guestimate of how
    # fast the boat will travel at the particular apparent wind angle.
    def compute_speed
      awa = @awa.abs
      return 0.0 if awa < 0.75
      ap = 1.0
      @speed = 0.0
      @polar_curve.each do |poly_val|
        @speed += poly_val * ap
        ap *= awa
      end
      @speed /= 2.5           # Fudge for small boat
      if @speed < 0.0
        @speed = 0.0
      end
    end

    #
    # Convert to a string
    def to_s
      "Heading %dd (wind %.1f@%dd, AWA:%dd, speed=%.2fknots)" % [heading_d, wind.distance, wind.angle_d, awa_d, speed]
    end
  end
end
