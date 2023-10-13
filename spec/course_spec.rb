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
  describe Course do
    let(:wind) { Bearing.new(Math::PI / 4, 10.0) }
    let(:waypoint) { double(distance: 100.0, bearing: Bearing.new(Math::PI / 2, 0.0)) }

    describe '.initialize' do
      it 'sets the default values' do
        course = Course.new
        expect(course.awa).to eq(0.0)
        expect(course.speed).to eq(0.0)
        expect(course.wind).to be_instance_of(Bearing)
        expect(course.heading).to eq(0)
      end

      it 'sets the wind to the provided value' do
        course = Course.new(wind)
        expect(course.wind).to eq(wind)
      end
    end

    describe '.heading=' do
      it 'sets the heading and updates AWA' do
        course = Course.new(wind)
        course.heading = Math::PI / 6
        expect(course.heading).to eq(Math::PI / 6)
        expect(course.awa).to eq(wind.angle - (Math::PI / 6))
      end

      it 'normalizes the heading when greater than 2*PI' do
        course = Course.new(wind)
        course.heading = 3 * Math::PI
        expect(course.heading).to eq(Math::PI)
      end

      it 'normalizes the heading when negative' do
        course = Course.new(wind)
        course.heading = -Math::PI / 4
        expect(course.heading).to eq((7 * Math::PI) / 4)
      end
    end

    describe '.wind=' do
      it 'sets the wind and updates AWA' do
        course = Course.new(wind)
        new_wind = Bearing.new(0.0, 15.0)
        course.wind = new_wind
        expect(course.wind).to eq(new_wind)
        expect(course.awa).to eq(new_wind.angle - course.heading)
      end
    end

    describe '.awa=' do
      it 'sets the AWA and computes the speed' do
        course = Course.new(wind)
        course.awa = Math::PI / 3
        expect(course.awa).to eq(Math::PI / 3)
        expect(course.speed).not_to eq(0.0)
      end

      it 'normalizes the AWA when less than -PI' do
        course = Course.new(wind)
        course.awa = -3 * Math::PI / 2
        expect(course.awa).to eq(Math::PI / 2)
      end

      it 'normalizes the AWA when greater than PI' do
        course = Course.new(wind)
        course.awa = 3 * Math::PI / 2
        expect(course.awa).to eq(-Math::PI / 2)
      end
    end

    describe '.relative_vmg' do
      it 'calculates the relative VMG based on the waypoint' do
        course = Course.new(wind)
        vmg = course.relative_vmg(waypoint)
        expect(vmg).to be_within(0.001).of(0.0)
      end
    end

    describe '.compute_wind' do
      it 'computes the wind angle based on heading and AWA' do
        course = Course.new(wind)
        course.compute_wind
        expect(course.wind.angle).to eq(wind.angle)
      end
    end

    describe '.compute_speed' do
      it 'computes the speed based on the AWA' do
        course = Course.new(wind)
        course.awa = Math::PI
        course.compute_speed
        expect(course.speed).to eq(1.695373155450642)
      end
    end

    describe '.to_s' do
      it 'returns a formatted string representation' do
        course = Course.new(wind)
        course.heading = Math::PI / 3
        course.awa = Math::PI / 4
        expected_string = "Heading 59d (wind 10.0@45d, AWA:45d, speed=1.96knots)"
        expect(course.to_s).to eq(expected_string)
      end
    end
  end
end
