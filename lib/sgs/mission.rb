#!/usr/bin/env ruby
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
require 'date'
require 'yaml'

module SGS
  #
  # Handle a specific mission.
  class Mission
    attr_accessor :title, :url, :description, :state
    attr_accessor :launch_site, :launch_location
    attr_accessor :attractors, :repellors, :track
    attr_accessor :where, :time, :course, :distance

    STATE_AWAITING = 0
    STATE_READY_TO_START = 1
    STATE_START_TEST = 2
    STATE_ON_MISSION = 3
    STATE_COMPLETE = 4

    STATE_NAMES = [
      ["Awaiting Instructions", STATE_AWAITING],
      ["Ready to Start", STATE_READY_TO_START],
      ["Initial Testing", STATE_START_TEST],
      ["On-Mission", STATE_ON_MISSION],
      ["Mission Completed!", STATE_COMPLETE]
    ].freeze

    #
    # Load a new mission from the missions directory.
    def self.file_load(filename)
      parse YAML.load(File.open(filename))
    end

    #
    # Load a new mission from the missions directory.
    def self.parse(data)
      mission = new
      mission.parse(data)
      mission
    end

    #
    # Create the attractors and repellors as well as the track array
    # and other items. @where is our current TrackPoint, @current_wpt is
    # the waypoint we're working (-1 if none), @course is the heading/speed
    # the boat is on.
    def initialize
      @title = nil
      @url = nil
      @description = nil
      @state = STATE_AWAITING
      @launch_site = nil
      @launch_location = nil
      @attractors = []
      @repellors = []
      @track = nil
      @current_wpt = -1
      @start_time = @time = nil
      @where = nil
      @course = Course.new
      @distance = 0
      @swing = 60
    end

    #
    # Get the mission state - this is actually saved in the config block
    def get_state
      config = SGS::Config.load
      @state = config.mission_state
    end

    #
    # Print a user-friendly label for the state
    def state_name
      STATE_NAMES[@state][0]
    end

    #
    # Commence a mission...
    def commence(time = nil)
      @start_time = @time = time || Time.now
      @track = [TrackPoint.new(time, @where)]
      @current_wpt = 0
    end

    #
    # Terminate a mission.
    def terminate
      puts "***** Mission terminated! *****"
      @current_wpt = -1
    end

    #
    # Compute the best heading based on our current position and the position
    # of the current attractor. This is where the heavy-lifting happens
    def navigate
      return unless active?
      puts "Attempting to navigate to #{waypoint}"
      #
      # First off, compute distance and bearing from our current location
      # to every attractor and repellor.
      @attractors[@current_wpt..-1].each do |waypt|
        waypt.compute_bearing(@where)
        puts "Angle: #{waypt.bearing.angle_d}, Distance: #{waypt.bearing.distance} (adj:#{waypt.distance})"
      end
      @repellors.each do |waypt|
        waypt.compute_bearing(@where)
        puts "Angle: #{waypt.bearing.angle_d}, Distance: #{waypt.bearing.distance} (adj:#{waypt.distance})"
      end
      #
      # Right. Now look to see if we've achieved the current waypoint and
      # adjust, accordingly
      while active? and reached? do
        next_waypoint!
      end
      return unless active?
      puts "Angle to next waypoint: #{waypoint.bearing.angle_d}d"
      puts "Adjusted distance to waypoint is #{@distance}"
      #
      # Now, start the vector field analysis by examining headings either side
      # of the bearing to the waypoint.
      best_course = @course
      best_relvmg = 0.0
      puts "Currently on a #{@course.tack_name} tack (heading is #{@course.heading_d} degrees)"
      (-@swing..@swing).each do |alpha_d|
        puts ">> Computing swing of #{alpha_d} degrees"
        new_course = Course.new(@course.wind)
        new_course.heading = waypoint.bearing.angle + Bearing.dtor(alpha_d)
        #
        # Ignore head-to-wind cases, as they're pointless.
        next if new_course.speed < 0.001
        puts "AWA:#{new_course.awa_d}, heading:#{new_course.heading_d}, speed:#{new_course.speed}"
        relvmg = 0.0
        relvmg = new_course.relative_vmg(@attractors[@current_wpt])
        @attractors[@current_wpt..-1].each do |waypt|
          relvmg += new_course.relative_vmg(waypt)
        end
        @repellors.each do |waypt|
          relvmg -= new_course.relative_vmg(waypt)
        end
        relvmg *= 0.1 if new_course.tack != @course.tack
        puts "Relative VMG: #{relvmg}"
        if relvmg > best_relvmg
          puts "Best heading (so far)"
          best_relvmg = relvmg
          best_course = new_course
        end
      end
      puts "Best RELVMG: #{best_relvmg}"
      puts "TACKING!" if best_course.tack != @course.tack
      puts "New HDG: #{best_course.heading_d} (AWA:#{best_course.awa_d}), WPT:#{waypoint.name}"
      @course = best_course
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
    # On-mission means we have something to do. In other words, we have a
    # waypoint to get to.
    def active?
      @current_wpt >= 0 and @current_wpt < @attractors.count
    end

    #
    # How long has the mission been active?
    def elapsed
      @time - @start_time
    end

    #
    # Return the current waypoint.
    def waypoint
      active? ? @attractors[@current_wpt] : nil
    end

    #
    # Have we reached the waypoint? Note that even though the waypoints have
    # a "reached" circle, we discard the last 10m on the basis that it is
    # within the GPS error.
    def reached?
      @distance = @attractors[@current_wpt].distance
      puts "ARE WE THERE YET? (dist=#{@distance})"
      return true if @distance <= 0.0027
      #
      # Check to see if the next WPT is nearer than the current one
      #if @current_wpt < (@attractors.count - 1)
      #  next_wpt = @attractors[@current_wpt + 1]
      #  brng = @attractors[@current_wpt].location - next_wpt.location
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
      raise "No mission currently active" unless active?
      @current_wpt += 1
      puts "Attempting to navigate to #{waypoint.name}" if active?
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
      start_wpt = active? ? @current_wpt : 0
      dist = 0.0
      loc = @where
      @attractors[start_wpt..-1].each do |wpt|
        wpt.compute_bearing(loc)
        dist += wpt.bearing.distance
        loc = wpt.location
      end
      dist
    end

    #
    # Parse mission data from a hash.
    def parse(data)
      @title = data["title"] || "Untitled Mission"
      @url = data["url"]
      @description = data["description"]
      if data["launch"]
        @launch_site = data["launch"]["name"] || "Launch Site"
        @launch_location = SGS::Location.parse data["launch"]
      end
      data["attractors"].each do |waypt_data|
        waypt = Waypoint.parse(waypt_data)
        waypt.attractor = true
        @attractors << waypt
      end
      data["repellors"].each do |waypt_data|
        waypt = Waypoint.parse(waypt_data)
        waypt.attractor = false
        @repellors << waypt
      end
    end

    #
    # Return a YAML string from the mission data
    def to_yaml
      to_hash.to_yaml
    end

    #
    # Convert the mission into a hash
    def to_hash
      hash = {"title" => @title}
      hash["url"] = @url if @url
      hash["description"] = @description if @description
      if @launch_location
        hash["launch"] = @launch_location.to_hash
        hash["launch"]["site"] = @launch_site
      end
      hash["attractors"] = []
      @attractors.each do |waypt|
        hash["attractors"] << waypt.to_hash
      end
      hash["repellors"] = []
      hash
    end
  end
end
