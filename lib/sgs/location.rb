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
# Routines for handling sailboat location and bearings.
#
require 'date'
require 'json'

module SGS
  #
  # Nominal radius of the planet, in nautical miles.
  # http://en.wikipedia.org/wiki/Earth_radius#Mean_radii
  EARTH_RADIUS = 3440.069528437724

  ##
  #
  # Class for dealing with latitude/longitude. Includes methods for parsing,
  # converting to a printable string, and so forth.
  #
  # Note that for convenience, we retain latitude and longitude in Radians
  # rather than degrees.
  #
  class Location
    attr_accessor :latitude, :longitude

    #
    # Create the Location instance.
    def initialize(lat = nil, long = nil)
      @latitude = lat.to_f if lat
      @longitude = long.to_f if long
    end

    #
    # The difference between two locations is a Bearing
    def -(loc)
      puts "Distance from #{self} to #{loc}"
      Bearing.compute(self, loc)
    end

    #
    # Calculate a new position from the current position
    # given a bearing (angle and distance)
    #
    # This code was derived from formulae on the Movable Type site:
    # http://www.movable-type.co.uk/scripts/latlong.html
    #
    # var lat2 = Math.asin( Math.sin(lat1)*Math.cos(d/R) + 
    #              Math.cos(lat1)*Math.sin(d/R)*Math.cos(angle) );
    # var lon2 = lon1 + Math.atan2(Math.sin(angle)*Math.sin(d/R)*Math.cos(lat1), 
    #                     Math.cos(d/R)-Math.sin(lat1)*Math.sin(lat2));
    def +(bearing)
      loc = Location.new
      sin_angle = Math.sin(bearing.angle)
      cos_angle = Math.cos(bearing.angle)
      sin_dstr = Math.sin(bearing.distance / SGS::EARTH_RADIUS)
      cos_dstr = Math.cos(bearing.distance / SGS::EARTH_RADIUS)
      sin_lat1 = Math.sin(@latitude)
      cos_lat1 = Math.cos(@latitude)
      loc.latitude = Math.asin(sin_lat1*cos_dstr + cos_lat1*sin_dstr*cos_angle)
      sin_lat2 = Math.sin(@latitude)
      loc.longitude = @longitude + Math.atan2(sin_angle*sin_dstr*cos_lat1,
                                              cos_dstr - sin_lat1*sin_lat2)
      loc
    end

    #
    # Move to the new location
    def move!(bearing)
      loc = calculate(bearing)
      self.latitude = loc.latitude
      self.longitude = loc.longitude
    end

    #
    # Create a new location from a string.
    # Uses the instance method to parse.
    def self.parse_str(str)
      loc = new
      loc.parse_str(str)
      loc
    end

    #
    # Create a new location from a lat/long string pair
    # Uses the instance method to parse.
    def self.parse(latstr, longstr)
      loc = new
      loc.parse(latstr, longstr)
      loc
    end

    #
    # Parse a lat/long value (in degrees)
    def parse_str(str)
      latstr, longstr = str.split(',')
      parse(latstr, longstr)
    end

    #
    # Parse a lat/long value pair (in degrees)
    def parse(latstr, longstr)
      @latitude = ll_parse(latstr.split, "NS")
      @longitude = ll_parse(longstr.split, "EW")
    end

    #
    # Is this location valid?
    def valid?
      @latitude and @longitude
    end

    #
    # Display the lat/long as a useful string (in degrees).
    def to_s
      if valid?
        "%s, %s" % [ll_to_s(@latitude, "NS"), ll_to_s(@longitude, "EW")]
      else
        "unknown"
      end
    end

    #
    # Display the lat/long as it would appear in a KML file.
    def to_kml(sep = ',')
      vals = [@longitude, @latitude, 0.0]
      str_vals = vals.map {|val| "%.8f" % Bearing.rtod(val)}
      str_vals.join(sep)
    end

    #
    # Helper functions for working in degrees.
    def latitude_d
      Bearing.rtod @latitude
    end

    def latitude_d=(val)
      @latitude = Bearing.dtor val
    end

    def latitude_array(fmt = nil)
      make_ll_array latitude_d, "NS", fmt
    end

    def longitude_d
      Bearing.rtod @longitude
    end

    def longitude_d=(val)
      @longitude = Bearing.dtor val
    end

    def longitude_array(fmt = nil)
      make_ll_array longitude_d, "EW", fmt
    end

    #
    # Subtract one location from another, returning a bearing
    def -(loc)
      Bearing.compute(self, loc)
    end

  private
    #
    # Parse a string into a lat or long.
    def ll_parse(args, nsew)
      dir = args[-1].gsub(/[\d\. ]+/, '').upcase
      args.map! {|val| val.to_f}
      val = args.shift
      val = val + args.shift / 60.0 if args.length > 0
      val = val + args.shift / 3600.0 if args.length > 0
      Bearing.dtor val * ((nsew.index(dir) == 1) ? -1 : 1)
    end

    #
    #
    def ll_to_s(val, str)
      if val < 0.0
        chr = str[1]
        val = -val
      else
        chr = str[0]
      end
      "%8.6f%c" % [Bearing.rtod(val), chr]
    end

    #
    # Create a Lat/Long array suitable for an NMEA output
    def make_ll_array(val, nsew, fmt = nil)
      fmt ||= "%02d%07.4f"
      if (val < 0)
        val = -val
        ne = nsew[1]
      else
        ne = nsew[0]
      end
      deg = val.to_i
      val = (val - deg) * 60
      [fmt % [deg, val], ne.chr]
    end
  end

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
