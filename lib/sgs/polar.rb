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
# The code on this page was derived from formulae on the Movable Type site:
# http://www.movable-type.co.uk/scripts/latlong.html
#

require 'date'

module SGS
  ##
  #
  # A class to handle boat polar calculations. It takes a range of polars
  # as polynomials and then applies them.
  class Polar
    # Right now, we have one polar - from a Catalina 22.
    # Note that the speed is the same, regardless of the tack.
    STANDARD = [
       -3.15994,
       23.8741,
      -27.4595,
       16.4868,
       -5.15663,
        0.743936,
       -0.0344716
    ].freeze

    #
    # set up the default values
    def initialize
      @curve = STANDARD
    end

    #
    # Compute the hull speed from the polar
    # :awa: is the apparent wind angle (in radians)
    # :wspeed: is the wind speed (in knots)
    def speed(awa, wspeed = 0.0)
      awa = awa.to_f.abs
      ap = 1.0
      @speed = 0.0
      @curve.each do |poly_val|
        @speed += poly_val * ap
        ap *= awa
      end
      @speed /= 1.529955
      if @speed < 0.0
        @speed = 0.0
      end
      @speed
    end

    #
    # Calculate the VMG from the angle to the mark.
    def vmg(alpha)
      Math::cos(alpha) * @speed
    end
  end
end
