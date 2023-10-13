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
  describe Mission do
    let(:mission) { Mission.new }

    describe '.initialize' do
      it 'sets the initial title to nil' do
        expect(mission.title).to be_nil
      end

      it 'sets the initial url to nil' do
        expect(mission.url).to be_nil
      end

      it 'sets the initial description to nil' do
        expect(mission.description).to be_nil
      end

      it 'sets the initial launch_site to nil' do
        expect(mission.launch_site).to be_nil
      end

      it 'sets the initial launch_location to nil' do
        expect(mission.launch_location).to be_nil
      end

      it 'sets the initial attractors to an empty array' do
        expect(mission.attractors).to eq([])
      end

      it 'sets the initial repellors to an empty array' do
        expect(mission.repellors).to eq([])
      end

      it 'loads the mission status' do
        allow(MissionStatus).to receive(:load)
        mission = Mission.new
        expect(MissionStatus).to have_received(:load)
      end
    end

    describe '.file_load' do
      it 'loads a mission from a YAML file' do
        filename = 'mission.yml'
        allow(YAML).to receive(:load).and_return({})
        allow(File).to receive(:open)
        Mission.file_load(filename)
        expect(File).to have_received(:open).with(filename)
      end
    end

    describe '.parse' do
      it 'creates a new mission object and parses the data' do
        data = { "title" => "Mission 1" }
        mission = Mission.parse(data)
        expect(mission).to be_a(Mission)
        expect(mission.title).to eq("Mission 1")
      end
    end

    describe '.parse' do
      it 'parses mission data from a hash' do
        data = {
          "title" => "Mission 1",
          "url" => "http://example.com",
          "description" => "Mission description",
          "launch" => {
            "site" => "Launch Site",
            "latitude" => 37.7749,
            "longitude" => -122.4194
          },
          "attractors" => [
            { "latitude" => 37.7749, "longitude" => -122.4194 }
          ],
          "repellors" => [
            { "latitude" => 37.7749, "longitude" => -122.4194 }
          ]
        }
        mission.parse(data)
        expect(mission.title).to eq("Mission 1")
        expect(mission.url).to eq("http://example.com")
        expect(mission.description).to eq("Mission description")
        expect(mission.launch_site).to eq("Launch Site")
        expect(mission.launch_location).to be_a(Location)
        expect(mission.attractors.length).to eq(1)
        expect(mission.repellors.length).to eq(1)
      end
    end

    describe '.to_yaml' do
      it 'returns a YAML string representation of the mission data' do
        mission.title = "Mission 1"
        expect(mission.to_yaml).to eq("---\ntitle: Mission 1\nattractors: []\nrepellors: []\n")
      end
    end

    describe '.to_hash' do
      it 'converts the mission into a hash' do
        mission.title = "Mission 1"
        mission.url = "http://example.com"
        mission.description = "Mission description"
        mission.launch_site = "Launch Site"
        mission.launch_location = Location.new(0.659296379, -2.136621598)
        attr1 = Location.new(0.659296379, -2.136621598)
        repp1 = Location.new(0.659296379, -2.136621598)
        mission.attractors << Waypoint.new(attr1, 0.0, 0.1, "Attractor #1")
        mission.repellors << Waypoint.new(repp1, 0.0, 10.0, "Repellor #1", false)

        hash = mission.to_hash

        expect(hash).to eq({
          "title" => "Mission 1",
          "url" => "http://example.com",
          "description" => "Mission description",
          "launch" => {
            "site" => "Launch Site",
            "latitude" => 37.7749,
            "longitude" => -122.4194
          },
          "attractors" => [
            { "latitude"=>37.7749,
              "longitude"=>-122.4194,
              "name"=>"Attractor #1",
              "normal"=>0.0,
              "range"=>0.1
            },
          ],
          "repellors" => [
            { "latitude"=>37.7749,
              "longitude"=>-122.4194,
              "name"=>"Repellor #1",
              "normal"=>0.0,
              "range"=>10.0
            }
          ]
        })
      end
    end
  end
end
