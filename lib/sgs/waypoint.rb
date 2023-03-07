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
# Routines for handling sailboat navigation and route planning.
#
module SGS
  #
  # Waypoint, Attractor, and Repellor definitions
  class Waypoint
    attr_accessor :location, :normal, :range, :name, :attractor
    attr_reader :bearing, :distance

    @@count = 0

    #
    # Parse a waypoint from a hash. Uses the instance method to do the work.
    def self.parse(data)
      waypt = new
      waypt.parse(data)
      waypt
    end

    #
    # Parse the waypoint data and save it
    def parse(data)
      @@count += 1
      @name = data["name"] || "Waypoint ##{@@count}"
      @location = Location.parse(data)
      @normal = data["normal"] || 0.0
      @range = data["range"] || 0.1
    end

    #
    # Define a new Attractor or Repellor, based on certain parameters.
    # The location is the centre of the waypoint. The normal is the compass
    # angle of the start of the semicircle, and the range is the size of
    # the arc. You can specify an optional name for the waypoint and also
    # indicate if we should be attracted or repelled by it.
    def initialize(location = nil, normal = 0.0, range = 0.1, name = "", attractor = true)
      @location = location || Location.new
      @normal = normal
      @range = range
      @name = name
      @attractor = attractor
      @bearing = nil
      @distance = 0
    end

    #
    # Calculate the back-vector from the waypoint to the specified position.
    # Calculate the adjusted distance between the position and the mark.
    # Check to see if our back-bearing from the waypoint to our location is
    # inside the chord of the waypoint, which is a semicircle commencing at
    # the normal. If so, reduce the distance to the waypoint by the length
    # of the chord. @distance is the adjusted distance to the location
    def compute_bearing(loc)
      @bearing = loc - @location
      @distance = @bearing.distance
      d = Bearing.new(@bearing.back_angle - @normal, @bearing.distance)
      # A chord angle of 0 gives a semicircle from 0 to 180 degrees. If our
      # approach angle is within range, then reduce our distance to the mark
      # by the chord distance (range).
      @distance -= @range if d.angle >= 0.0 and d.angle < Math::PI
      @distance = 0.0 if @distance < 0.0
      @distance
    end

    #
    # Is this an attractor?
    def attractor?
      @attractor == true
    end

    #
    # Is this a repellor?
    def repellor?
      @attractor == true
    end

    #
    # Is the waypoint in scope? In other words, is our angle inside the chord.
    def in_scope?
      puts "In-scope distance is %f..." % @distance
      @distance == 0.0
    end

    #
    # Convert the waypoint normal to/from degrees
    def normal_d
      Bearing.rtod @normal
    end

    #
    # Convert the waypoint normal to/from degrees
    def normal_d=(val)
      @normal = Bearing.dtor val
    end

    #
    # Convert to a hash
    def to_hash
      hash = @location.to_hash
      hash["name"] = @name
      hash["normal"] = @normal
      hash["range"] = @range
      hash
    end

    #
    # Pretty version of the waypoint.
    def to_s
      "'#{@name}' at #{@location} => #{normal_d}%#{@range}"
    end

    #
    # Display a string for a KML file
    def to_kml
      puts "TO KML!"
      #p self
      #c2 = @chord.clone
      #c2.angle += Math::PI
      #pos1 = @location.calculate(@chord)
      #pos2 = @location.calculate(c2)
      #"#{pos1.to_kml(',')} #{pos2.to_kml(',')}"
    end

    #
    # Show the axis line for the waypoint (as a KML)
    def to_axis_kml
      puts "TO_AXIS_KML!"
      #::FIXME::
      #c2 = @chord.clone
      #c2.angle += 1.5 * Math::PI
      #pos1 = @location.calculate(c2)
      #"#{@location.to_kml(',')} #{pos1.to_kml(',')}"
    end
  end

  #
  # Store an individual track point.
  class TrackPoint
    attr_accessor :time, :location

    def initialize(time = nil, location = nil)
      @time = time ? time.clone : nil
      @location = location ? location.clone : nil
    end
  end
end
