
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
  describe Bearing do
    subject { Bearing.new(0, 10) }

    # Trinity College Dublin
    let(:loc1) { Location.new(0.9310282965575151, -0.10918010110276395) }
    # Buckingham Palace
    let(:loc2) { Location.new(0.8988640251982394, -0.0024844063770438486) }

    describe '.initialize' do
      it 'should initialize a Bearing instance' do
        expect(subject).to be_instance_of(Bearing)
      end

      it 'should initialize the angle and distance' do
        expect(subject.angle).to eq(0)
        expect(subject.distance).to eq(10.0)
      end
    end

    describe '.degrees' do
      it 'should initialize a Bearing instance from degrees' do
        bearing = Bearing.degrees(45, 10)
        expect(bearing.angle).to eq(Math::PI / 4)
        expect(bearing.distance).to eq(10.0)
      end
    end

    describe '.dtor' do
      it 'should convert degrees to radians' do
        expect(Bearing.dtor(45)).to eq(Math::PI / 4)
      end
    end

    describe '.rtod' do
      it 'should convert radians to degrees' do
        expect(Bearing.rtod(Math::PI / 4)).to eq(45)
      end
    end

    describe '.xtor' do
      it 'should convert boat angle (in hex) to radians' do
        expect(Bearing.xtor(384)).to eq(Math::PI)
      end
    end

    describe '.rtox' do
      it 'should convert radians to hex-degrees' do
        expect(Bearing.rtox(Math::PI)).to eq(128)
      end
    end

    describe '.absolute' do
      it 'should re-adjust an angle away from negative' do
        expect(Bearing.absolute(-1.5 * Math::PI)).to eq(0.5 * Math::PI)
      end
    end

    describe '.absolute_d' do
      it 'should re-adjust an angle (in degrees) away from negative' do
        expect(Bearing.absolute_d(-90)).to eq(270)
      end
    end

    describe '.compute' do
      it 'should calculate the distance and angle between two locations' do
        bearing = Bearing.compute(loc1, loc2)
        expect(bearing.angle).to be_within(0.1).of(1.98)
        expect(bearing.distance).to be_within(10).of(250)
      end
    end

    describe '.distance_m' do
      it 'return the distance in metres' do
        bearing = Bearing.new(0, 10)
        expect(bearing.distance_m).to eq(18520.0)
      end
    end

    describe '.to_s' do
      it 'converts the bearing to a string' do
        bearing = Bearing.compute(loc1, loc2)
        expect(bearing.to_s).to eq("BRNG 113d,249.576NM")
      end
    end
  end
end
