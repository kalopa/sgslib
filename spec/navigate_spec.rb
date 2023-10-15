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
  describe Navigate do
    let(:mission) { Mission.new }
    let(:gps) { GPS.new }
    let(:otto) { Otto.new }
    let(:navigate) { Navigate.new(mission) }

    before do
      allow(GPS).to receive(:load).and_return(gps)
      allow(Otto).to receive(:load).and_return(otto)
    end

    describe '.initialize' do
      it 'sets the mission and swing instance variables' do
        expect(navigate.instance_variable_get(:@mission)).to eq(mission)
        expect(navigate.instance_variable_get(:@swing)).to eq(45)
      end
    end

    describe '.navigate' do
      context 'when the current waypoint is -1' do
        before do
          allow(mission).to receive_message_chain(:status, :current_waypoint).and_return(-1)
          allow(mission).to receive_message_chain(:status, :current_waypoint=)
          allow(mission).to receive_message_chain(:status, :distance=)
        end
      end

      context 'when GPS data is valid' do
        before do
          allow(gps).to receive(:valid?).and_return(true)
        end

        it 'loads the latest GPS and Otto data' do
          expect(GPS).to receive(:load).and_return(gps)
          expect(Otto).to receive(:load).and_return(otto)
          navigate.navigate
        end

        #it 'computes a new course' do
        #  allow(gps).to receive(:valid?).and_return(true)
        #  allow(otto).to receive(:compass)
        #  allow(otto).to receive(:awa)
        #  allow(otto).to receive(:wind)
        #  expect(navigate).to receive(:compute_new_course)
        #  navigate.navigate
        #end
      end

      context 'when GPS data is invalid' do
        before do
          allow(gps).to receive(:valid?).and_return(false)
        end

        #it 'does not compute a new course' do
        #  expect(navigate).not_to receive(:compute_new_course)
        #  navigate.navigate
        #end
      end
    end

    describe '.compute_new_course' do
      #it 'performs the vector field analysis and returns the best course' do
      #  expect(navigate).to receive(:puts).at_least(:once)
      #  expect(Course).to receive(:new).and_return(double('course', tack_name: 'tack_name', heading_d: 0.0))
      #  expect(navigate).to receive(:puts).with('Best course:')
      #  expect(navigate).to receive(:p)
      #  navigate.compute_new_course
      #end
    end
  end
end
