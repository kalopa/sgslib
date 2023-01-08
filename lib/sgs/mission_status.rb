#!/usr/bin/env ruby
#
# Copyright (c) 2023, Kalopa Robotics Limited.  All rights reserved.
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
# Mission state
#
module SGS
  #
  # Handle a specific mission.
  class MissionStatus < RedisBase
    attr_accessor :state, :current_waypoint, :start_time, :end_time

    STATE_AWAITING = 0
    STATE_READY_TO_START = 1
    STATE_START_TEST = 2
    STATE_RADIO_CONTROL = 3
    STATE_COMPASS_FOLLOW = 4
    STATE_WIND_FOLLOW = 5
    STATE_COMPLETE = 6
    STATE_TERMINATED = 7
    STATE_FAILURE = 8

    STATE_NAMES = [
      ["Awaiting Instructions", STATE_AWAITING],
      ["Ready to Start", STATE_READY_TO_START],
      ["Initial Testing", STATE_START_TEST],
      ["On-Mission - Radio Control", STATE_RADIO_CONTROL],
      ["On-Mission - Track Compass Heading", STATE_COMPASS_FOLLOW],
      ["On-Mission - Track Wind Direction", STATE_WIND_FOLLOW],
      ["Mission Completed!", STATE_COMPLETE],
      ["Mission Terminated", STATE_TERMINATED],
      ["Mission Failure", STATE_FAILURE]
    ].freeze

    #
    # Create the attractors and repellors as well as the track array
    # and other items. @where is our current TrackPoint, @current_wpt is
    # the waypoint we're working (-1 if none), @course is the heading/speed
    # the boat is on.
    def initialize
      @state = STATE_AWAITING
      @current_waypoint = 0
      @start_time = @end_time = nil
      @logger = Logger.new(STDOUT)
    end

    #
    # Print a user-friendly label for the state
    def state_name
      STATE_NAMES[@state][0]
    end

    #
    # Are we actively on-mission?
    def active?
      @state >= STATE_START_TEST && @state < STATE_COMPLETE
    end

    #
    # Commence a mission...
    def start_test!(time = nil)
      @logger.warn "***** Starting test phase *****"
      @start_time = time || Time.now
      @state = STATE_START_TEST
      @current_waypoint = 0
      save_and_publish
    end

    #
    # Terminate a mission.
    def completed!(time = nil)
      @end_time = time || Time.now
      @state = STATE_COMPLETE
      save_and_publish
      @logger.warn "***** Mission completed! *****"
    end

    #
    # Terminate a mission.
    def terminate!(time = nil)
      @end_time = time || Time.now
      @state = STATE_TERMINATED
      save_and_publish
      @logger.warn "***** Mission terminated! *****"
    end

    #
    # Terminate a mission.
    def failure!(time = nil)
      @end_time = time || Time.now
      @state = STATE_FAILURE
      save_and_publish
      @logger.warn "***** Mission failure! *****"
    end
  end
end
