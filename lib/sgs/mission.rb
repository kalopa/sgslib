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
require 'date'

module SGS
  #
  # Handle a specific mission.
  class Mission
    attr_accessor :id, :where, :time, :start_time
    attr_accessor :course, :heading, :twa, :vmg
    attr_accessor :waypoints, :repellors, :track
    attr_accessor :root_dir

    #
    # Create the attractors and repellors
    def initialize(id = 0)
      @root_dir = "."
      @waypoints = []
      @repellors = []
      @track = []
      @id = id
      @time = DateTime.now
      @wpt_index = -1
      @heading = -1
      @course = -1
      @tack = 0
    end

    #
    # Load a new mission from the missions directory.
    def self.load(id)
      mission = new
      mission.id = id
      mission.read(File.open(mission.filename))
      mission
    end

    #
    # Parse a mission file.
    def read(file)
      file.each do |line|
        unless line =~ /^#/
          args = line.split(':')
          code = args[0]
          loc = Location.parse_str(args[1])
          vec = Bearing.degrees(args[2], args[3])
          name = args[4].strip
          case code
          when /\d/
            @waypoints[code.to_i] = Waypoint.new(loc, vec, name)
          when /[Xx]/
            @where = loc
            @wind = vec
            compute_heading if active?
          when /[Rr]/
            @repellors << Waypoint.new(loc, vec, name, Waypoint::REPELLOR)
          end
        end
      end
      @wpt_index = -1
    end

    #
    # Save the mission.
    def save
      write(File.open(filename, 'w'))
    end

    #
    # Write a mission to a file.
    def write(file)
      file.puts "#\n# My starting position."
      file.puts "X:%s:0:12:Starting position" % @where
      file.puts "#\n# Waypoints."
      @waypoints.each_with_index do |wpt, i|
        file.puts "%d:%s:%d:%f:%s" % [i,
                                      wpt.location,
                                      wpt.chord.angle_degrees,
                                      wpt.chord.distance,
                                      wpt.name]
      end
    end

    #
    # Commence a mission...
    def commence(time = nil)
      @start_time = time || DateTime.now
      @time = @start_time
      @wpt_index = 0
      @have_new_waypoint = true
      @have_new_heading = true
      @have_new_tack = false
    end

    #
    # Terminate a mission.
    def terminate
      @wpt_index = -1
    end

    #
    # On-mission means we have something to do. In other words, we have a
    # waypoint to get to.
    def active?
      @wpt_index >= 0 and @wpt_index < @waypoints.count
    end

    #
    # Set our current  location (and timestamp).
    def set_location(where, time = nil)
      @where = where
      @time = time || DateTime.now
      #
      # Update the track with our new position, and find the next waypoint.
      @track << Track.new(@time, @where.clone)
      again = false
      begin
        wpt = @waypoints[@wpt_index]
        puts ">>Waypoint is #{wpt}"
        wpt.compute_bearing(@where)
        puts ">>Course #{wpt.bearing}"
        if wpt.in_scope?
          puts "We're at the mark. Time to find the next waypoint..."
          @wpt_index += 1
          @have_new_waypoint = again = true
        else
          again = false
        end
      end while again and active?
      #
      # OK, now compute our heading...
      if active?
        newc = wpt.bearing.angle_degrees
        if newc != @course
          puts "New course: #{newc}"
          @course = newc
          compute_heading
        end
      end
    end
    #
    # Compute the most effective TWA/VMG for the course.
    # Because I tend to forget, here's a run-down of the terminology...
    # @course is where we're trying to get to. It is our compass bearing to the
    # next mark or finish or whatever. @heading is the compass bearing we're
    # going to sail to, which may not be the same as our course (we can't sail
    # upwind, for example). alpha is the difference between our heading and the
    # course. @twa is the true wind angle, relative to the front of the boat.
    # Negative values mean a port tack, positive values are starboard. @vmg is
    # the velocity made-good. In other words, the speed at which we're heading
    # to the mark. It's defined as Vcos(alpha) where V is the velocity through
    # the water.
    def compute_heading
      puts "Computing Heading and TWA..."
      wad = @wind.angle_degrees.to_i
      puts "Wind angle:%03dd" % wad
      puts "Required course:%03dd" % @course
      polar = Polar.new
      @twa ||= 0
      #
      # Try an alpha angle between -60 and +60 degrees either side of the
      # course. The point of this exercise is to compute the TWA for that
      # heading, compute the speed at that trial TWA, and then compute
      # the VMG for it. We compute the maximum VMG (and TWA) and use that
      # to drive the boat. The PVMG is the poisoned version of the VMG,
      # adjusted so that the opposite tack is less-favoured.
      ideal_twa = 0
      ideal_vmg = 0.0
      max_pvmg = 0.0
      curr_tack = @twa < 0.0 ? -1 : 1
      puts "Current tack is %d" % curr_tack
      (-60..60).each do |alpha|
        newh = Bearing.absolute_degrees(@course + alpha)
        twa = 180 - (720 + wad - @course - alpha) % 360
        puts "Trial heading of %03dd (alpha=%d, TWA=%d)" % [newh, alpha, twa]
        speed = polar.speed(Bearing.degrees_to_radians(twa))
        vmg = polar.vmg(Bearing.degrees_to_radians(alpha))
        #
        # Adjust the speed to favour the current tack.
        tack_err = twa < 0.0 ? -curr_tack : curr_tack
        pvmg = vmg + vmg * tack_err / 5.0
        if vmg > 1.7 and false
          puts "Trial TWA: %3d, speed:%.5fkn, VMG:%.6fkn" % [twa, speed, vmg]
        end
        if pvmg > max_pvmg
          max_pvmg = pvmg
          ideal_twa = twa
          ideal_vmg = vmg
        end
      end
      #
      # For the various angles, we have computed the best TWA and VMG. Now
      # adjust our settings, accordingly. Don't use the poisoned VMG.
      @twa = ideal_twa
      @vmg = ideal_vmg
      @have_new_tack = (@twa * curr_tack) < 0
      puts "> Best TWA is %d, VMG is %.6fknots" % [@twa, @vmg]
      #
      # Check to see if we have a new heading.
      newh = Bearing::absolute_degrees(wad - @twa)
      puts "> HDG:%03dd, Err:%03dd" % [newh, newh - @course]
      if newh != @heading
        puts "New Heading! %03dd" % newh
        @have_new_heading = true
        @heading = newh
      end
    end

    #
    # Set the wind data.
    def wind_data(angle, speed = 0.0)
      @wind = Bearing.degrees(angle, speed)
      puts "Wind:#{@wind}"
      compute_heading if active?
    end

    #
    # Wind speed (Beaufort scale)
    BEAUFORT = [0, 1, 4, 7, 11, 17, 22, 28, 34, 41]
    def wind_beaufort
      ws = @wind.speed
    end

    #
    # Are we at a new waypoint?
    def new_waypoint?
      hnw = @have_new_waypoint
      @have_new_waypoint = false
      active? and hnw
    end

    #
    # Do we have a new heading?
    def new_heading?
      hnh = @have_new_heading
      @have_new_heading = false
      active? and hnh
    end

    #
    # Do we need to tack?
    def tacking?
      hnt = @have_new_tack
      @have_new_tack = false
      active? and hnt
    end

    #
    # Return the next (current) waypoint.
    def waypoint
      active? ? @waypoints[@wpt_index] : nil
    end
    #
    # Return the mission status as a string
    def status_str
      mins = (@time - @start_time) * 24.0 * 60.0
      hours = (mins / 60.0).to_i
      days = hours / 24
      mins = (mins % 60.0).to_i
      hours %= 24
      str = ">>>#{@time}, "
      if days < 1
        str += "%dh%dm" % [hours, mins]
      else
        str += "%dd%dh" % [days, mins]
      end
      str + ": My position is #{@where}"
    end

    #
    # Name/path of mission file.
    def filename
      @root_dir + "/missions/%03d" % id
    end

    #
    # Save the track.
    def track_save
      kml_write(File.open(track_filename, 'w'))
    end

    #
    # The name of the track file
    def track_filename
      @root_dir + "/tracks/output-%03d.kml" % id
    end

    #
    # Write the track data as a KML file.
    def kml_write(file)
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.kml('xmlns' => 'http://www.opengis.net/kml/2.2',
                'xmlns:gx' => 'http://www.google.com/kml/ext/2.2') {
          xml.Folder {
            xml_line_style(xml, "waypointLine", "0xffcf0000", 4)
            xml_line_style(xml, "repellorLine", "0xff00007f", 4)
            xml_line_style(xml, "trackLine")
            @waypoints.each do |wpt|
              xml.Placemark {
                xml.name wpt.name
                xml.styleUrl "#waypointLine"
                xml.LineString {
                  xml.extrude 1
                  xml.tessellate 1
                  xml.coordinates wpt.to_kml
                }
              }
              xml.Placemark {
                xml.styleUrl "#waypointLine"
                xml.LineString {
                  xml.extrude 1
                  xml.tessellate 1
                  xml.coordinates wpt.to_axis_kml
                }
              }
            end
      # Requires a hack to get rid of the 'gx:' for the when tag.
      file.puts builder.to_xml.gsub(/GX_/, 'gx:')
    end

    #
    # Do a line style. The colour is of the form aabbggrr for some unknown
    # reason...
    def xml_line_style(xml, label, color = "0xffffffff", width = 1)
      xml.Style(:id => label) {
        xml.LineStyle {
          xml.color color
          xml.width width
          xml.GX_labelVisibility 1
        }
      }
    end
  end
end
