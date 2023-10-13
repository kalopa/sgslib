#
# Copyright (c) 2014-2023, Kalopa Robotics Limited.  All rights
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
require 'spec_helper'

module SGS
  describe Alarm do
    describe '.name' do
      it 'returns the correct name for an alarm code' do
        alarm = Alarm.new
        expect(alarm.name(Alarm::VBATT_CRITICAL)).to eq("Battery voltage is critically low")
      end
    end

    describe '.build_include' do
      it 'creates an include file with the correct alarm definitions' do
        fname = "test_alarm_include.h"
        Alarm.build_include(fname)
        file_contents = File.read(fname)
        expect(file_contents).to include("#define SGS_ALARM_MISSION_SWITCH\t0")
        expect(file_contents).to include("#define SGS_ALARM_RUDDSRV_FAULT\t\t1")
        expect(file_contents).to include("#define SGS_ALARM_SAILSRV_FAULT\t\t2")
        expect(file_contents).to include("#define SGS_ALARM_VBATT_CRITICAL\t3")
        expect(file_contents).to include("#define SGS_ALARM_VBATT_UNDERVOLTAGE\t4")
        expect(file_contents).to include("#define SGS_ALARM_VBATT_OVERVOLTAGE\t5")
        expect(file_contents).to include("#define SGS_ALARM_VSOLAR_OVERVOLTAGE\t8")
        expect(file_contents).to include("#define SGS_ALARM_WDI_STUCK\t\t11")
        expect(file_contents).to include("#define SGS_ALARM_WDI_NOREAD\t\t12")
        expect(file_contents).to include("#define SGS_ALARM_RUDDER_NOZERO\t\t13")
        expect(file_contents).to include("#define SGS_ALARM_SAIL_NOZERO\t\t14")
        expect(file_contents).to include("#define SGS_ALARM_OTTO_RESTART\t\t16")
        expect(file_contents).to include("#define SGS_ALARM_WAYPOINT_REACHED\t20")
        File.delete(fname)
      end
    end
  end
end
