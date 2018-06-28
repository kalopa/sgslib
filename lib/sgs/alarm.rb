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
# Routines for handling sailboat alarms. Note that this is the definitive
# list of alarms on the system. To add or modify an alarm, do so here.
#
require 'date'

module SGS
  ##
  # Deal with alarm subsystem.
  #
  class Alarm < RedisBase
    attr_accessor :last_report, :time

    OTTO_RESTART = 0
    RUDDSRV_FAULT = 1
    SAILSRV_FAULT = 2
    VBATT_CRITICAL = 3
    VBATT_UNDERVOLTAGE = 4
    VBATT_OVERVOLTAGE = 5
    IBATT_INRUSH = 6
    IBATT_DRAIN = 7
    VSOLAR_OVERVOLTAGE = 8
    COMPASS_ERROR = 9
    COMPASS_NOREAD = 10
    WDI_STUCK = 11
    WDI_NOREAD = 12
    RUDDER_NOZERO = 13
    SAIL_NOZERO = 14
    MOTHER_UNRESP = 15

    MISSION_COMMENCE = 16
    MISSION_COMPLETE = 17
    MISSION_ABORT = 18
    WAYPOINT_REACHED = 19
    CROSS_TRACK_ERROR = 20
    INSIDE_FENCE = 21

    ALARM_NAMES = [
      "OTTO Restarted",
      "Rudder Servo Fault",
      "Sail Servo Fault",
      "Battery voltage is critically low",
      "Battery voltage is low",
      "Battery voltage is too high",
      "Battery inrush current",
      "Battery drain current",
      "Solar voltage is too high",
      "Compass module error",
      "Compass not responding",
      "WDI reading is misaligned",
      "Cannot read from the WDI",
      "Cannot zero the rudder position",
      "Cannot zero the sail position",
      "Mother is unresponsive",
      "Mission has commenced",
      "Mission is completed",
      "*** MISSION ABORT ***",
      "Waypoint has been reached",
      "Significant cross-track error",
      "Vessel is inside the fence"
    ].freeze

    def initialize
      @count = 0
      @last_report = nil
      @time = Array.new(32, Time.at(0))
      super
    end

    #
    # Convert an alarm number into a string.
    def name(alarmno)
      MESSAGES[alarmno]
    end
  end
end
