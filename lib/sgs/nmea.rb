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
# Routines for handling sailboat navigation and route planning.
#
module SGS
  class NMEA
    ##
    # Parse and create NMEA strings for various purposes.
    #
    attr_accessor :args, :valid, :checksum

    def initialize
      @args = Array.new
      @valid = false
      @checksum = 0
    end

    #
    # Parse an NMEA string into its component parts.
    def self.parse(str)
      nmea = new
      if nmea.parse(str) < 0
        nmea = nil
      end
      nmea
    end
    
    #
    # Parse an NMEA string into its component parts.
    def parse(str)
      str.chomp!
      if str[0] != 36
        return -1
      end
      str, sum = str[1..-1].split('*')
      if sum.nil? or sum.to_i(16) != compute_csum(str)
        return -1
      end
      @args = str.split(',')
      @args.count
    end

    #
    # Is the current line a GPRMC message?
    def is_gprmc?
      @args[0] == "GPRMC"
    end

    #
    # Parse a GPRMC message
    # ["GPRMC", "211321.000", "A", "5309.7743", "N", "00904.5576", "W", "0.17", "78.41", "200813", "", "", "A"]
    def parse_gprmc
      if @args.count < 12 or @args.count > 13
        return nil
      end
      gps = SGS::GPS.new
      gps.valid = @args[2] == "A"
      hh = @args[1][0..1].to_i
      mm = @args[1][2..3].to_i
      ss = @args[1][4..-1].to_f
      us = (ss % 1.0 * 1000000)
      ss = ss.to_i
      dd = @args[9][0..1].to_i
      mn = @args[9][2..3].to_i
      yy = @args[9][4..5].to_i + 2000
      gps.time = Time.gm(yy, mn, dd, hh, mm, ss, us)
      gps.location = Location.parse ll_nmea(@args[3,4]), ll_nmea(@args[5,6])
      gps.sog = @args[7].to_f
      gps.cmg = Bearing.dtor @args[8].to_f
      gps
    end

    #
    # Output a GPRMC message
    def make_gprmc(gps)
      @valid = true
      @args = Array.new
      @args[0] = "GPRMC"
      @args[1] = gps.time.strftime("%H%M%S.") + "%03d" % (gps.time.usec / 1000)
      @args[2] = 'A'
      @args.concat gps.location.latitude_array
      @args.concat gps.location.longitude_array("%03d%07.4f")
      @args[7] = "%.2f" % gps.sog
      @args[8] = "%.2f" % Bearing.radians_to_d(gps.cmg)
      @args[9] = gps.time.strftime("%d%m%y")
      @args.concat ['', '']
      @args << 'A'
    end

    #
    # Convert an array of component parts into an NMEA string.
    def to_s
      str = @args.join(',')
      "$%s*%02X" % [str, compute_csum(str)]
    end

    #
    # Compute an NMEA checksum
    def compute_csum(str)
      @checksum = 0
      str.each_byte {|ch| @checksum ^= ch}
      @checksum
    end

  private
    #
    # Convert NMEA lat/long to something useful.
    def ll_nmea(args)
      args[0].gsub(/(\d\d\.)/, ' \1') + args[1]
    end
  end
end
