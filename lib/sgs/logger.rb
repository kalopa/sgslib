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
# Routines for handling sailboat logging.
#
require 'date'

module SGS
  #
  # Waypoint, Attractor, and Repellor definitions
  class Logger < RedisBase
    attr_accessor :watch

    #
    # Watch names and definitions. The first watch is from 8PM until
    # midnight (local time), the middle watch is from midnight until
    # 4AM. The morning watch is from 4AM until 8AM. The forenoon watch
    # runs from 8AM until noon and the afternoon watch runs from noon
    # until 4PM. The dog watches run from 4PM until 8PM and around we
    # go again.
    #
    # Logs are sent back to base every four hours (6 per day) starting
    # at midnight UTC. However, some of the reporting is based on
    # the watch system rather than UTC. For example, reporting battery
    # voltage is most useful at the start of the forenoon watch, because
    # this represents the lowest voltage point after driving the boat all
    # night. As a result, the watch ID is computed based on the longitude,
    # which is a rough approximation of the timezone.
    FIRST_WATCH = 0
    MIDDLE_WATCH = 1
    MORNING_WATCH = 2
    FORENOON_WATCH = 3
    AFTERNOON_WATCH = 4
    DOG_WATCH = 5
    ALARM_REPORT = 7

    WATCH_NAMES = [
      "First Watch", "Middle Watch", "Morning Watch",
      "Forenoon Watch", "Afternoon Watch", "Dog Watch",
      "", "** ALARM REPORT **"
    ].freeze

    def initialize()
      @watch = FIRST_WATCH
    end

    #
    # Convert the watch ID to a name
    def watch_name
      WATCH_NAMES[@watch]
    end

    #
    # Determine the watch report. This takes account our actual latitude
    # and the current time. It does a rudimentary timezone conversion and
    # calculates the watch. Note that what we're calculating here is what
    # was the previous watch. So any time after 23:45 (local), we'll report
    # from the First Watch. Right up until 03:45 (local) when we'll start
    # reporting from the Middle Watch.
    def determine_watch(longitude)
      utc = Time.now
      local_hour = utc.hour + longitude * 12.0 / Math::PI
      p utc
      p local_hour
      local_hour += 24.0 if local_hour < 0.0
      local_hour -= 24.0 if local_hour >= 24.0
      @watch = ((local_hour / 4.0) + 0.25).to_i
      @watch = FIRST_WATCH if @watch == 6
    end
  end
end
