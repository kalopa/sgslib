#!/bin/sh
#
# Copyright (c) 2014-2022, Kalopa Robotics Limited.  All rights
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
# Run this script when you first install the SGS software to make sure all
# of the various bits and pieces are properly installed and configured.
#

# Mount the root and config partitions in case we need them.
mount -w /
mount -w /cfg

# Install whatever Ruby gems we need.
gem install daemons -v 1.2.6
gem install god -v 0.13.7
gem install serialport -v 1.3.1
gem install redis -v 3.3.5
gem install mini_portile2 -v 2.3.0
gem install nokogiri -v 1.8.3
gem install msgpack -v 1.2.4
gem install sgslib

# Make sure Redis is running properly.
mkdir -p /app/redis
chown redis:redis /app/redis
/etc/local/rc.d/redis restart
redis-cli -i 1 info | grep -e ^redis -e uptime

# Do the initial configuration of the Redis data
ruby -r sgslib -e SGS::Config.configure_all

# Install the god-particles.
cp /app/mother/god.conf /etc
cp /app/mother/god.conf /cfg
/app/rc.d/god restart
god status

exit 0
