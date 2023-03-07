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
# Routines for handling sailboat location.
#
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
    # Create the Location instance. Latitude and longitude passed in radians.
    def initialize(lat = nil, long = nil)
      @latitude = lat.to_f if lat
      @longitude = long.to_f if long
    end

    #
    # The difference between two locations is a Bearing
    def -(loc)
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
      sin_dstr = Math.sin(bearing.distance / EARTH_RADIUS)
      cos_dstr = Math.cos(bearing.distance / EARTH_RADIUS)
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
    # Create a new location from a lat/long hash.
    # Uses the instance method to parse.
    def self.parse(data)
      loc = new
      loc.parse(data)
      loc
    end

    #
    # Parse the lat/long values passed as a string. This function
    # should be able to handle any type of lat/long string, in most
    # general formats. See :to_s for examples.
    def parse(data)
      llvals = data.split /,/
      if llvals.count == 1
        #
        # Must be space-separated. Try that...
        llvals = data.split(/ /)
        if llvals.count != 2
          raise ArgumentError.new "Cannot split lat/long values"
        end
      elsif llvals.count != 2
        #
        # Too many comma separators.
        raise ArgumentError.new "Invalid lat/long values"
      end
      self.latitude_d = _ll_parse(llvals[0], "NS")
      self.longitude_d = _ll_parse(llvals[1], "EW")
      true
    end

    #
    # Parse the lat/long from a hash object.
    def parse_hash(data = {})
      self.latitude_d = _ll_parse(data["latitude"], "NS")
      self.longitude_d = _ll_parse(data["longitude"], "EW")
    end

    #
    # Is this location valid?
    def valid?
      @latitude and @longitude
    end

    #
    # Convert the lat/long to a hash.
    def to_hash
      {"latitude" => latitude_d.round(6), "longitude" => longitude_d.round(6)}
    end

    #
    # Display the lat/long as a useful string (in degrees). Output
    # formats are as follows (default is :d):
    # :d    "48.104051, -7.282614"
    # :dd   "48.104051N, 7.282614W"
    # :dmm  "48 6.243060N, 7 16.956840W"
    # :dms  "48 6 14.583600N, 7 16 57.410400W"
    def to_s(opts = {})
      if valid?
        lat_str = _ll_conv(latitude_d.round(6), "NS", opts)
        lon_str = _ll_conv(longitude_d.round(6), "EW", opts)
        "#{lat_str}, #{lon_str}"
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
    # Return the latitude in degrees.
    def latitude_d
      Bearing.rtod @latitude
    end

    #
    # Set the latitude using a value in degrees.
    def latitude_d=(val)
      @latitude = Bearing.dtor val
    end

    #
    # Produce a latitude array for NMEA output.
    def latitude_array(fmt = nil)
      _make_ll_array latitude_d, "NS", fmt
    end

    #
    # Return the longitude in degrees.
    def longitude_d
      Bearing.rtod @longitude
    end

    #
    # Set the longitude using a value in degrees.
    def longitude_d=(val)
      @longitude = Bearing.dtor val
    end

    #
    # Produce a longitude array for NMEA output.
    def longitude_array(fmt = nil)
      _make_ll_array longitude_d, "EW", fmt
    end

    #
    # Subtract one location from another, returning a bearing
    def -(loc)
      Bearing.compute(self, loc)
    end

    private
      #
      # Parse a latitude or longitude value, from a wide range of
      # formats. Should handle D.ddd, D M.mmm and D M S.sss values.
      # Can also strip out the special degrees unicode, as well as
      # single and double quotes.
      def _ll_parse(arg, nsew)
        str = arg.chomp.gsub /[\u00B0'"]/, ' '
        if str[-1].upcase =~ /[#{nsew}]/
          sign = (str[-1].upcase == nsew[1]) ? -1 : 1
          str[-1] = ' '
        else
          sign = 1
        end
        args = str.split
        raise ArgumentError.new "Cannot parse lat/long value" if args.count > 3
        value = 0.0
        (args.count - 1).downto(0).each do |idx|
          value = args[idx].to_f + value / 60.0
        end
        sign * value
      end

      #
      # Convert a latitude/longitude to a string. Can specify
      # multiple output formats such as :d, :dd, :dmm, :dms to
      # format according to various different styles.
      def _ll_conv(value, nsew, opts)
        format = opts[:format] || :d
        return "%.6f" % value if format == :d
        if value < 0.0
          suffix = nsew[1]
          value = -value
        else
          suffix = nsew[0]
        end
        case opts[:format] || :d
        when :dd
          "%.6f%s" % [value, suffix]
        when :dmm
          dd = value.to_i
          mm = (value - dd.to_f) * 60.0
          "%d %.6f%s" % [dd, mm, suffix]
        when :dms
          dd = value.to_i
          value = (value - dd.to_f) * 60.0
          mm = value.to_i
          ss = (value - mm.to_f) * 60.0
          "%d %d %.6f%s" % [dd, mm, ss, suffix]
        end
      end

      #
      # Create a Lat/Long array suitable for an NMEA output.
      def _make_ll_array(val, nsew, fmt = nil)
        fmt ||= "%02d%07.4f"
        if (val < 0)
          val = -val
          suffix = nsew[1]
        else
          suffix = nsew[0]
        end
        deg = val.to_i
        val = (val - deg) * 60
        [fmt % [deg, val], suffix.chr]
      end
  end
end
