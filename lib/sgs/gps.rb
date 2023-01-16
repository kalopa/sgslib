#
# Copyright (c) 2013-2023, Kalopa Robotics Limited.  All rights
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
require 'serialport'

module SGS
  class GPS < RedisBase
    attr_accessor :time, :location, :sog, :cmg, :magvar

    def initialize(lat = nil, long = nil)
      @time = Time.new(2000, 1, 1)
      @location = Location.new(lat, long)
      @sog = 0.0
      @cmg = 0.0
      @magvar = nil
      @valid = false
      super()
    end

    #
    # Main daemon function (called from executable)
    def self.daemon
      puts "GPS reader starting up..."
      config = SGS::Config.load

      sp = SerialPort.new config.gps_device, config.gps_speed
      sp.read_timeout = 10000

      loop do
        nmea = SGS::NMEA.parse sp.readline
        if nmea.is_gprmc?
          gps = nmea.parse_gprmc
          p gps
          gps.save_and_publish if gps and gps.valid?
        end
      end
    end

    #
    # Set the validity
    def is_valid
      @valid = true
    end

    #
    # Is the GPS data valid?
    def valid?
      @valid == true
    end
  end
end
