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
# All of the code to navigate a sailboat to a series of waypoints is defined
# herein. The main Navigate class does not save anything to Redis, it
# is purely a utility class for navigation. The navigation is based on my
# paper "An Attractor/Repellor Approach to Autonomous Sailboat Navigation".
# https://link.springer.com/chapter/10.1007/978-3-319-72739-4_6
#
# We save a copy of the actual mission so we can find the attractors and
# repellors. We also assume that doing a GPS.load will pull the latest
# GPS co-ordinates and an Otto.load will pull the latest telemetry from
# the boat. Specifically, the GPS will give us our lat/long and the Otto
# data will allow us to compute the actual wind direction (as well as the
# boat heading and apparent wind angle).
#

##
#
module SGS
  class Navigate
    attr_reader :course, :gps, :otto, :waypoint

    #
    # Initialize the navigational parameters
    def initialize(mission)
      @mission = mission
      @course = nil
      @swing = 45
    end

    #
    # Compute the best heading based on our current position and the position
    # of the current attractor. This is where the heavy-lifting happens.
    # Returns TRUE if we're done.
    def navigate
      if @mission.status.current_waypoint == -1
        @mission.status.current_waypoint = 0
        @mission.status.distance = 0
      end
      set_waypoint
      puts "Attempting to navigate to #{@waypoint}..."
      pull_gps_data
      pull_otto_data
      return compute_new_course
    end

    #
    # Compute a new course based on our position and other information.
    def compute_new_course
      #
      # Update our local copy of the course based on what Otto says.
      puts "Compute new course..."
      unless @course
        #
        # First time through, the current course is whichever way the boat
        # is pointing.
        @course = Course.new
        @course.heading = @otto.compass
      end
      #
      # Really it's the AWA we're interested in, not the boat heading.
      @course.awa = @otto.awa
      @course.compute_wind
      p @course
      #
      # First off, compute distance and bearing from our current location
      # to every attractor and repellor. We only look at forward attractors,
      # not ones behind us.
      compute_bearings(@mission.attractors[@mission.status.current_waypoint..-1])
      compute_bearings(@mission.repellors)
      #
      # Right. Now look to see if we've achieved the current waypoint and
      # adjust, accordingly
      while active? and reached?
        next_waypoint!
      end
      return true unless active?
      puts "Angle to next waypoint: #{@waypoint.bearing.angle_d}d"
      puts "Adjusted distance to waypoint is #{@waypoint.distance}"
      #
      # Now, start the vector field analysis by examining headings either side
      # of the bearing to the waypoint.
      best_course = @course
      best_relvmg = 0.0
      puts "Currently on a #{@course.tack_name} tack (heading is #{@course.heading_d} degrees)"
      (-@swing..@swing).each do |alpha_d|
        new_course = Course.new(@course.wind)
        new_course.heading = waypoint.bearing.angle + Bearing.dtor(alpha_d)
        #
        # Ignore head-to-wind cases, as they're pointless. When looking at
        # the list of waypoints to compute relative VMG, only look to the next
        # three or so waypoints.
        next if new_course.speed < 0.001
        relvmg = 0.0
        relvmg = new_course.relative_vmg(@mission.attractors[@mission.status.current_waypoint])
        end_wpt = @mission.status.current_waypoint + 3
        if end_wpt >= @mission.attractors.count
          end_wpt = @mission.attractors.count - 1
        end
        @mission.attractors[@mission.status.current_waypoint..end_wpt].each do |waypt|
          relvmg += new_course.relative_vmg(waypt)
        end
        @mission.repellors.each do |waypt|
          relvmg -= new_course.relative_vmg(waypt)
        end
        relvmg *= 0.1 if new_course.tack != @course.tack
        if relvmg > best_relvmg
          best_relvmg = relvmg
          best_course = new_course
        end
      end
      puts "Best course: AWA: #{best_course.awa_d} degrees, Course: #{best_course.heading_d} degrees, Speed: #{best_course.speed} knots"
      p best_course
      if best_course.tack != @course.tack
        puts "TACKING!!!!"
      end
      @course = best_course
      return false
    end

    #
    # Compute the bearing for every attractor or repellor
    def compute_bearings(waypoints)
      waypoints.each do |waypt|
        waypt.compute_bearing(@gps.location)
      end
    end

    #
    # Set new position
    def set_position(time, loc)
      @where = loc
      @time = time
      @track << TrackPoint.new(@time, @where)
    end

    #
    # Advance the mission by a number of seconds (computing the new location
    # in the process). Fake out the speed and thus the location.
    def simulated_movement(how_long = 60)
      puts "Advancing mission by #{how_long}s"
      distance = @course.speed * how_long.to_f / 3600.0
      puts "Travelled #{distance * 1852.0} metres in that time."
      set_position(@time + how_long, @where + Bearing.new(@course.heading, distance))
    end

    #
    # How long has the mission been active?
    def elapsed
      @time - @start_time
    end

    #
    # Check we're active - basically, are there any more waypoints left?
    def active?
      @mission.status.current_waypoint < @mission.attractors.count
    end

    #
    # Have we reached the waypoint? Note that even though the waypoints have
    # a "reached" circle, we discard the last 10m on the basis that it is
    # within the GPS error.
    def reached?
      puts "ARE WE THERE YET? (dist=#{@waypoint.distance})"
      p @waypoint
      return true if @waypoint.distance <= 0.0054
      #
      # Check to see if the next WPT is nearer than the current one
      #if current_wpt < (@mission.attractors.count - 1)
      #  next_wpt = @mission.attractors[@current_wpt + 1]
      #  brng = @mission.attractors[@current_wpt].location - next_wpt.location
      #  angle = Bearing.absolute(waypoint.bearing.angle - next_wpt.bearing.angle)
      #  return true if brng.distance > next_wpt.distance and
      #                 angle > (0.25 * Math::PI) and
      #                 angle < (0.75 * Math::PI)
      #end
      puts "... Sadly, no."
      return false
    end

    #
    # Advance to the next waypoint. Return TRUE if
    # there actually is one...
    def next_waypoint!
      @mission.status.current_waypoint += 1
      puts "Attempting to navigate to new waypoint: #{waypoint}"
      set_waypoint
    end

    #
    # Set the waypoint instance variable based on where we are
    def set_waypoint
      @waypoint = @mission.attractors[@mission.status.current_waypoint]
    end

    #
    # Return the mission status as a string
    def status_str
      mins = elapsed / 60
      hours = mins / 60
      mins %= 60
      days = hours / 24
      hours %= 24
      str = ">>> #{@time}, "
      if days < 1
        str += "%dh%02dm" % [hours, mins]
      else
        str += "+%dd%%02dh%02dm" % [days, hours, mins]
      end
      str + ": My position is #{@where}"
    end

    #
    # Compute the remaining distance from the current location
    def overall_distance
      dist = 0.0
      loc = @where
      @mission.attractors[@mission.status.current_waypoint..-1].each do |wpt|
        wpt.compute_bearing(loc)
        dist += wpt.bearing.distance
        loc = wpt.location
      end
      dist
    end

    #
    # Pull the latest GPS data. Failure is not an option.
    def pull_gps_data
      loop do
        @gps = GPS.load
        puts "GPS: #{@gps}"
        break if @gps.valid?
        puts "Retrying GPS..."
        sleep 1
      end
    end

    #
    # Pull the latest Otto data.
    def pull_otto_data
      #
      # Pull the latest Otto data...
      @otto = Otto.load
      puts "OTTO:"
      p @otto
      puts "Compass: #{@otto.compass}"
      puts "AWA: #{@otto.awa}"
      puts "Wind: #{@otto.wind}"
    end

    #
    # Navigate a course up to a windward mark which is one nautical mile
    # upwind of the start position. From there, navigate downwind to the
    # finish position
    def upwind_downwind_course
    end

    #
    # Navigate around an olympic triangle. Sail one nautical mile upwind of
    # the current position, then sail to a point to the left-side of the
    # course which is at an angle of 120 degrees to the wind. From there,
    # sail back to the start position
    def olympic_course
    end

    #
    # Navigate the mission. This is the main "meat and potatoes" navigation.
    # It concerns itself with finding the best route to the next mark and
    # sailing to that
    def mission
    end

    #
    # The mission has ended - sail to the rendezvous point
    def mission_end
    end

    #
    # The mission is aborted. Determine what to do next
    def mission_abort
    end

    #
    # What is our current position?
    def curpos
      @curpos ||= GPS.load
    end

    #
    # What is the next waypoint?
    def waypoint
      @waypoint ||= Waypoint.load
    end
  end
end
