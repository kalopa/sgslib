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

##
# Routines for manipulating data in Redis.
#
require 'redis'

module SGS
  class RedisBase
    class << self
      def redis
        @@redis ||= Redis.new
      end
    end

    #
    # The base (inherited) class for dealing with Redis data for
    # the navigation system. Each model class inherits this parent,
    # and gets an update count for free.

    #
    # Initialize the (sub-)class variables in Redis.
    def self.setup
      cls = new
      cls.instance_variables.each do |var|
        val = cls.instance_variable_get var
        if val.kind_of? Array
          #
          # Arrays are handled separately. We instead
          # use the index to create a series of 'fooN'
          # variables.
          val.size.times do |idx|
            var_init var, val, idx
          end
        else
          var_init var, val
        end
      end
    end

    #
    # Initialize a Redis variable.
    def self.var_init(var, val, idx = nil)
      cls = new
      RedisBase.redis.setnx cls.make_redis_name(var, :idx => idx), self.to_redis(var, val, idx)
    end

    #
    # Load the instance variables for the class.
    def self.load()
      cls = new
      cls.load
      cls
    end

    #
    # Load the instance variables for the class.
    def load
      instance_variables.each do |var|
        lval = instance_variable_get var
        if lval.kind_of? Array
          #
          # It's an array - iterate and read the values.
          lval.size.times do |idx|
            idx_val = lval[idx]
            lval[idx] = redis_read_var var, idx_val.class, :idx => idx 
         end
        elsif lval.kind_of? Location
          #
          # ::FIXME:: Yes. this is a hack.
          # This belongs in the Location class itself. It's arguable that a lot
          # of the stuff belongs in the parent class. Perhaps the thing to do
          # is ask the class to return a hash of names and values, and then
          # set them accordingly.
          lval.latitude = redis_read_var var, Float, :name => 'latitude'
          lval.longitude = redis_read_var var, Float, :name => 'longitude'
        else
          lval = redis_read_var var, lval.class
        end
        instance_variable_set var, lval
      end
      true
    end

    #
    # Write the instance to Redis. IWe produce a Hash of keys and values. From
    # this and inside a Redis "multi" block, we set all the values and finally
    # increment the count. @count is actually an instance variable of redis_base
    def save
      #
      # Get the Hash of settable values (including count).
      var_list = {}
      self.instance_variables.each do |var|
        lval = self.instance_variable_get var
        if lval.kind_of? Array
          lval.size.times do |idx|
            var_list[make_redis_name(var, :idx => idx)] = self.class.to_redis var, lval, idx
          end
        elsif lval.kind_of? Location
          #
          # ::FIXME:: Yes. this is a hack. see 'load' above.
          var_list[make_redis_name(var, :name => 'latitude')] = lval.latitude
          var_list[make_redis_name(var, :name => 'longitude')] = lval.longitude
        else
          var_list[make_redis_name(var)] = self.class.to_redis var, lval
        end
      end
      #
      # Inside a multi-block, set all the variables and increment
      # the count.
      RedisBase.redis.multi do |pipeline|
        var_list.each do |key, value|
          pipeline.set key, value
        end
        pipeline.incr count_name
      end
      true
    end

    #
    # Publish the count onto a Redis pub/sub channel. The trick to subscribing
    # to a channel is that whenever there's a publish, the new count is
    # published as a string. If you subscribe to the channel (usually the
    # class name), you can remember the last received count and decide if
    # there is fresh data. Or, you can just act anyway.
    def publish
      RedisBase.redis.publish self.class.redis_handle, count.to_s
    end

    #
    # Subscribe to messages from this particular channel. Each count is sent
    # to the code block. It's up to the called code block to decide if the
    # count has changed and if so, to read the data from Redis.
    def self.subscribe
      redis = Redis.new
      redis.subscribe(redis_handle) do |on|
        on.message do |channel, count|
          yield count.to_i
        end
      end
    end

    #
    # Combined save and publish
    def save_and_publish
      save && publish
    end

    #
    # Retrieve the count
    def count
      RedisBase.redis.get count_name
    end

    #
    # What is the official name of the count instance variable
    def count_name
      make_redis_name "@count"
    end

    #
    # Get an instance variable value from a Redis value.
    def redis_read_var(var, klass, opts = {})
      redis_name = make_redis_name var, opts
      redis_val = RedisBase.redis.get redis_name
      redis_val = nil if redis_val == ""
      if redis_val
        if not klass or klass == NilClass
          redis_val = true if redis_val == "true"
          redis_val = false if redis_val == "false"
          klass = Float if redis_val =~ /[0-9+-\.]+/
        end
        case
        when klass == Time
          redis_val = Time.at(redis_val.to_f).gmtime
        when klass == Fixnum
          redis_val = redis_val.to_i
        when klass == Float
          redis_val = redis_val.to_f
        when klass == FalseClass
          redis_val = (redis_val == "true" or redis_val == "TRUE")
        when klass == TrueClass
          redis_val = (redis_val == "true" or redis_val == "TRUE")
        end
      end
      redis_val
    end

    #
    # Set a variable - convert from Ruby format to Redis format.
    # As of now, we only convert times. Floats and integers are
    # dealt with by Redis (converted to strings, unfortunately).
    def self.to_redis(var, local_val, idx = nil)
      if local_val
        local_val = local_val[idx] if idx
        if local_val.class == Time
          local_val = local_val.to_f
        end
      end
      local_val
    end

    #
    # Translate an instance variable into a Redis key name.
    # This is simply the class name, a dot and the instance
    # variable. A bit of jiggery-pokery to convert the
    # instance variable into a proper name. Probably an easier
    # way to do this, but...
    #
    # Instance method for above
    def make_redis_name(var, opts = {})
      var_name = opts[:name] || var.to_s.gsub(/^@/, '')
      prefix = opts[:prefix] || self.class.redis_handle
      if opts[:idx]
        "#{prefix}.#{var_name}#{opts[:idx] + 1}"
      else
        "#{prefix}.#{var_name}"
      end
    end

    #
    # Convert the class name into something suitable for Redis
    def self.redis_handle
      self.name.downcase.gsub(/^sgs::/, 'sgs_')
    end
  end
end
