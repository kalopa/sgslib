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
  describe MissionStatus do
    let(:mission_status) { MissionStatus.new }

    describe '.initialize' do
      it 'sets the initial state to STATE_AWAITING' do
        expect(mission_status.state).to eq(MissionStatus::STATE_AWAITING)
      end

      it 'sets the initial current_waypoint to -1' do
        expect(mission_status.current_waypoint).to eq(-1)
      end

      it 'sets the initial distance to 0' do
        expect(mission_status.distance).to eq(0)
      end
    end

    describe '.state_name' do
      it 'returns the user-friendly name for the current state' do
        mission_status.state = MissionStatus::STATE_READY_TO_START
        expect(mission_status.state_name).to eq("Ready to Start")
      end
    end

    describe '.active?' do
      it 'returns true if the mission is actively on-mission' do
        mission_status.state = MissionStatus::STATE_START_TEST
        expect(mission_status.active?).to be true
      end

      it 'returns false if the mission is not actively on-mission' do
        mission_status.state = MissionStatus::STATE_TERMINATED
        expect(mission_status.active?).to be false
      end
    end

    describe '.start_test!' do
      it 'sets the state to STATE_START_TEST' do
        mission_status.start_test!
        expect(mission_status.state).to eq(MissionStatus::STATE_START_TEST)
      end

      it 'sets the start_time' do
        time = Time.now
        mission_status.start_test!(time)
        expect(mission_status.start_time).to eq(time)
      end

      it 'sets the current_waypoint to 0' do
        mission_status.start_test!
        expect(mission_status.current_waypoint).to eq(0)
      end
    end

    describe '.completed!' do
      it 'sets the state to STATE_COMPLETE' do
        mission_status.completed!
        expect(mission_status.state).to eq(MissionStatus::STATE_COMPLETE)
      end

      it 'sets the end_time' do
        time = Time.now
        mission_status.completed!(time)
        expect(mission_status.end_time).to eq(time)
      end
    end

    describe '.terminate!' do
      it 'sets the state to STATE_TERMINATED' do
        mission_status.terminate!
        expect(mission_status.state).to eq(MissionStatus::STATE_TERMINATED)
      end

      it 'sets the end_time' do
        time = Time.now
        mission_status.terminate!(time)
        expect(mission_status.end_time).to eq(time)
      end
    end

    describe '.failure!' do
      it 'sets the state to STATE_FAILURE' do
        mission_status.failure!
        expect(mission_status.state).to eq(MissionStatus::STATE_FAILURE)
      end

      it 'sets the end_time' do
        time = Time.now
        mission_status.failure!(time)
        expect(mission_status.end_time).to eq(time)
      end
    end
  end
end
