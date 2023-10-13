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
  describe Location do
    describe '.initialize' do
      it 'sets the latitude and longitude' do
        location = Location.new(0.839574073, -0.127105592)
        expect(location.latitude_d).to eq(48.104050971508485)
        expect(location.longitude_d).to eq(-7.2826139741118)
      end
    end

    describe '.parse' do
      it 'parses latitude and longitude from a string' do
        location = Location.new
        location.parse('48.104051, -7.282614')
        expect(location.latitude).to eq(0.8395740734972708)
        expect(location.longitude).to eq(-0.1271055924518343)
      end

      it 'raises an error when given an invalid lat/long string' do
        location = Location.new
        expect { location.parse('invalid') }.to raise_error(ArgumentError)
      end
    end

    describe '.valid?' do
      it 'returns true if latitude and longitude are set' do
        location = Location.new(0.839574073, -0.127105592)
        expect(location.valid?).to be true
      end

      it 'returns false if latitude or longitude is not set' do
        location = Location.new(48.104051, nil)
        expect(location.valid?).to be false
      end
    end

    describe '.to_s' do
      it 'returns a string representation of latitude and longitude' do
        location = Location.new(0.839574073, -0.127105592)
        expect(location.to_s).to eq('48.104051, -7.282614')
      end

      it 'returns "unknown" when location is not valid' do
        location = Location.new
        expect(location.to_s).to eq('unknown')
      end
    end

    describe '.to_hash' do
      it 'returns a hash representation of latitude and longitude' do
        location = Location.new(0.839574073, -0.127105592)
        expect(location.to_hash).to eq({ 'latitude' => 48.104051, 'longitude' => -7.282614 })
      end
    end

    describe '.to_kml' do
      it 'returns a string representation in KML format' do
        location = Location.new(0.839574073, -0.127105592)
        expect(location.to_kml).to eq("-7.28261397,48.10405097,0.00000000")
      end

      it 'uses a custom separator when provided' do
        location = Location.new(0.839574073, -0.127105592)
        expect(location.to_kml(';')).to eq("-7.28261397;48.10405097;0.00000000")
      end
    end
  end
end
