#!/usr/bin/env ruby
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
# Mostly this class is for the overall daemon running on Mother. It takes
# care of listening for GPS updates and adjusting the sailing route,
# accordingly. It is responsible for keeping MissionStatus up to
# date. The actual mission information is stored in a YAML file.
#

##
# Routines for handling sailboat navigation and route planning.
#
require 'yaml'

module SGS
  #
  # Handle a specific mission.
  class Mission
    attr_accessor :title, :url, :description
    attr_accessor :launch_site, :launch_location
    attr_accessor :attractors, :repellors, :status

    #
    # Create the attractors and repellors as well as the track array
    # and other items.
    def initialize
      @title = nil
      @url = nil
      @description = nil
      @launch_site = nil
      @launch_location = nil
      @attractors = []
      @repellors = []
      @status = MissionStatus.load
      super
    end

    #
    # Main daemon function (called from executable)
    def self.daemon
      puts "Mission management system starting up..."
      #
      # Load the mission data from Redis and augment it with the
      # contents of the mission file.
      config = Config.load
      mission = Mission.file_load config.mission_file
      nav = Navigate.new(mission)
      otto = Otto.load
      #
      # Keep running in our mission state, forever.
      while true do
        if mission.status.active?
          #
          # Listen for GPS data. When we have a new position, call the
          # navigation code to determine a new course to sail (currently
          # a compass course), and set the Otto register accordingly.
          # Repeat until we run out of waypoints.
          GPS.subscribe do |count|
            puts "Mission received new GPS count: #{count}"
            new_course = nav.navigate
            if new_course.nil?
              mission.status.completed!
              break
            end
            mission.status.save
            compass = Bearing.rtox(new_course.heading)
            otto.set_register(Otto::COMPASS_HEADING_REGISTER, compass)
          end
        else
          sleep 60
          mission.status.load
        end
      end
    end

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
    # Parse mission data from a hash.
    def parse(data)
      @title = data["title"] || "Untitled Mission"
      @url = data["url"]
      @description = data["description"]
      if data["launch"]
        @launch_site = data["launch"]["site"] || "Launch Site"
        @launch_location = Location.parse data["launch"]
      end
      if data["attractors"]
        data["attractors"].each do |waypt_data|
          waypt = Waypoint.parse(waypt_data)
          waypt.attractor = true
          @attractors << waypt
        end
      end
      if data["repellors"]
        data["repellors"].each do |waypt_data|
          waypt = Waypoint.parse(waypt_data)
          waypt.attractor = false
          @repellors << waypt
        end
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
