#
# Copyright (c) 2013, Kalopa Research.  All rights reserved.  This is free
# software; you can redistribute it and/or modify it under the terms of the
# GNU General Public License as published by the Free Software Foundation;
# either version 2, or (at your option) any later version.
#
# It is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with this product; see the file COPYING.  If not, write to the Free
# Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.
#
# THIS SOFTWARE IS PROVIDED BY KALOPA RESEARCH "AS IS" AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
# OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
# IN NO EVENT SHALL KALOPA RESEARCH BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF
# USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

##
#
module SGS
  class Navigate
    attr_reader :mode

    MODE_SLEEP = 0
    MODE_TEST = 1
    MODE_MANUAL = 2
    MODE_UPDOWN = 3
    MODE_OLYMPIC = 4
    MODE_PRE_MISSION = 5
    MODE_MISSION = 6
    MODE_MISSION_END = 7
    MODE_MISSION_ABORT = 8

    MODENAMES = [
      "Sleeping...",
      "Test Mode",
      "Manual Steering",
      "Sail Up and Down",
      "Sail a Triangle",
      "Pre-Mission Wait",
      "On Mission",
      "Mission Ended",
      "** Mission Abort **"
    ].freeze

    def initialize
      @mode = MODE_SLEEP
      @waypoint = nil
      @curpos = nil
      super
    end

    #
    # What is the mode name?
    def mode_name
      MODENAMES[@mode]
    end

    def mode=(val)
      puts "SETTING NEW MODE TO #{MODENAMES[val]}"
      @mode = val
    end

    #
    # This is the main navigator function. It does several things;
    # 1. Look for the next waypoint and compute bearing and distance to it
    # 2. Decide if we have reached the waypoint (and adjust accordingly)
    # 3. Compute the boat heading (and adjust accordingly)
    def run
      puts "Navigator mode is #{mode_name}: Current Position:"
      p curpos
      p waypoint
      case @mode
      when MODE_UPDOWN
        upwind_downwind_course
      when MODE_OLYMPIC
        olympic_course
      when MODE_MISSION
        mission
      when MODE_MISSION_END
        mission_end
      when MODE_MISSION_ABORT
        mission_abort
      end
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
      @curpos ||= SGS::GPS.load
    end

    #
    # What is the next waypoint?
    def waypoint
      @waypoint ||= SGS::Waypoint.load
    end
  end
end
