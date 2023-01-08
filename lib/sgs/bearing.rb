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
# Routines for handling sailboat bearings.
#
require 'json'

module SGS
  ##
  # Class for dealing with the angle/distance vector.
  #
  # Note that for convenience, we retain the angle in Radians. The
  # distance is in nautical miles.
  class Bearing
    attr_accessor :distance

    #
    # Create the Bearing instance.
    def initialize(angle = 0.0, distance = 0.0)
      self.angle = angle.to_f
      self.distance = distance.to_f
    end

    #
    # Create a bearing from an angle in degrees.
    def self.degrees(angle, distance)
      new(Bearing.dtor(angle), distance)
    end

    #
    # Handy function to translate degrees to radians
    def self.dtor(deg)
      deg.to_f * Math::PI / 180.0
    end

    #
    # Handy function to translate radians to degrees
    def self.rtod(rad)
      rad.to_f * 180.0 / Math::PI
    end

    #
    # Handy function to re-adjust an angle away from negative
    def self.absolute(angle)
      (angle + 2.0 * Math::PI) % (2.0 * Math::PI)
    end

    #
    # Another handy function to re-adjust an angle (in degrees) away from
    # negative.
    def self.absolute_d(angle)
      (angle + 360) % 360
    end

    #
    # Haversine formula for calculating distance and angle, given two
    # locations.
    #
    # To calculate an angle and distance from two positions:
    #
    # This code was derived from formulae on the Movable Type site:
    # http://www.movable-type.co.uk/scripts/latlong.html
    #
    # var d = Math.acos(Math.sin(lat1)*Math.sin(lat2) + 
    #                  Math.cos(lat1)*Math.cos(lat2) *
    #                  Math.cos(lon2-lon1)) * R;
    # var y = Math.sin(dLon) * Math.cos(lat2);
    # var x = Math.cos(lat1)*Math.sin(lat2) -
    #         Math.sin(lat1)*Math.cos(lat2)*Math.cos(dLon);
    # var angle = Math.atan2(y, x).toDeg();
    def self.compute(loc1, loc2)
      bearing = new
      sin_lat1 = Math.sin(loc1.latitude)
      sin_lat2 = Math.sin(loc2.latitude)
      cos_lat1 = Math.cos(loc1.latitude)
      cos_lat2 = Math.cos(loc2.latitude)
      sin_dlon = Math.sin(loc2.longitude - loc1.longitude)
      cos_dlon = Math.cos(loc2.longitude - loc1.longitude)
      bearing.distance = Math.acos(sin_lat1*sin_lat2 + cos_lat1*cos_lat2*cos_dlon) *
                                SGS::EARTH_RADIUS
      y = sin_dlon * cos_lat2
      x = cos_lat1 * sin_lat2 - sin_lat1 * cos_lat2 * cos_dlon
      bearing.angle = Math.atan2(y, x)
      bearing
    end

    #
    # Set the angle
    def angle=(angle)
      @angle = Bearing.absolute(angle)
    end

    #
    # Get the angle
    def angle
      @angle
    end

    #
    # Return the angle (in degrees)
    def angle_d
      Bearing.rtod(@angle).to_i
    end

    #
    # Get the back-angle (the angle viewed from the opposite end of the line)
    def back_angle
      Bearing.absolute(@angle - Math::PI)
    end

    #
    # Convert to a string
    def to_s
      "BRNG %03dd,%.3fnm" % [angle_d, @distance]
    end
  end
end
