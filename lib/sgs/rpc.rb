#
# Copyright (c) 2018, Kalopa Research.  All rights reserved.  This is free
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
# Routines for sending and receiving messages using Redis.  Sourced from
# Anthoni Scotti, https://128bit.io/2014/08/31/rpc-using-redis/
#
require 'redis'
require 'securerandom'
require 'msgpack'

module SGS
  class RPCClient
    def initialize(channel)
      @channel = channel.to_s
    end

    def method_missing(name, *args)
      uuid = SecureRandom.uuid
      request = {
        'id' => uuid,
        'jsonrpc' => '2.0',
        'method' => name,
        'params' => args
      }
      SGS::RedisBase.redis.lpush(@channel, request.to_msgpack)
      channel, response = SGS::RedisBase.redis.brpop(uuid, timeout=60)
      MessagePack.unpack(response)['result']
    end
  end

  class RPCServer
    def initialize(channel, klass)
      @channel = channel.to_s
      @klass = klass
    end

    def start
      puts "Starting RPC server for #{@channel}"
      loop do
        channel, request = SGS::RedisBase.redis.brpop(@channel)
        request = MessagePack.unpack(request)

        puts "Working on request: #{request['id']}"

        args = request['params'].unshift(request['method'])
        result = @klass.send *args

        reply = {
          'jsonrpc' => '2.0',
          'result' => result,
          'id' => request['id']
        }

        SGS::RedisBase.redis.rpush(request['id'], MessagePack.pack(reply))
        SGS::RedisBase.redis.expire(request['id'], 30)
      end
    end
  end
end
