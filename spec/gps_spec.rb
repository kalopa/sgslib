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
  describe GPS do
    let(:gps) { GPS.new }

    describe '.initialize' do
      it 'sets the initial values correctly' do
        expect(gps.time).to be_a(Time)
        expect(gps.location).to be_a(Location)
        expect(gps.sog).to eq(0.0)
        expect(gps.cmg).to eq(0.0)
        expect(gps.magvar).to be_nil
        expect(gps.valid?).to be_falsey
      end
    end

    describe '.force' do
      it 'forces a GPS location and time' do
        lat = 52.370216
        long = 4.895168
        time = Time.new(2023, 6, 19, 10, 30, 0)

        gps.force(lat, long, time)

        expect(gps.time).to eq(time)
        expect(gps.location.latitude).to eq(lat)
        expect(gps.location.longitude).to eq(long)
        expect(gps.valid?).to be_truthy
      end
    end

    describe '.is_valid' do
      it 'sets the validity to true' do
        gps.is_valid
        expect(gps.valid?).to be_truthy
      end
    end

    describe '.to_s' do
      context 'when GPS data is valid' do
        it 'returns a string representation of the GPS data' do
          lat = 0.914032699
          long = 0.085436799
          time = Time.new(2023, 6, 19, 10, 30, 0)
          gps.force(lat, long, time)
          gps.sog = 10.5
          gps.cmg = 180.0

          expected_string = "@20230619-10:30:00, 52.370216, 4.895168, SOG:10.5, CMG:180.0"
          expect(gps.to_s).to eq(expected_string)
        end
      end

      context 'when GPS data is invalid' do
        it 'returns an error string' do
          expect(gps.to_s).to eq("GPS error")
        end
      end
    end
  end
end
