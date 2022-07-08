[![Gem Version](https://badge.fury.io/rb/sgslib.svg)](https://badge.fury.io/rb/sgslib)

# Sailboat Guidance System

The Sailboat Guidance System is a Ruby gem for managing an autonomous, robotic sailboat.
As it stands, it is quite specific to the
[Beoga Beag](https://kalopa.com/vessels/2) boat, but this will change, over time
(**and with your help!**).

The architecture is split between a low-level, Arduino-like board and an upper-level
FreeBSD-based board.
The low-level board controls the second-by-second operations such as steering,
sail trim, and battery voltage.
It is designed to focus on things such as real-time performace, tight PID-control
loops, and basic telemetry such as voltage/current measurement, electronic compass,
and wind direction.
The upper-level board has the advantage of floating-point and the disadvantage of
a pre-emptive, multiprocess operating system.
So it focuses on the "bigger picture."
In this world-view, the GPS is read by the upper-level system.
Likewise, any satellite communications are handled here.

This mimics the way an ocean-going, racing sailboat (such as a Volvo Ocean Race boat)
would organize itself.
The two watch teams alternate the constant, 24/7 job of steering and sail trim,
while the navigator analyses weather systems and makes more strategic decisions.

The code in this repository is designed to handle all of the upper-level tasks
associated with navigation, overall monitoring, reporting and logging, error
detection, and anything which can be done on an hourly cadence rather than the
tasks which require constant attention and control.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sgslib'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sgslib

## Usage

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies.
Then, run `rake spec` to run the tests.
You can also run `bin/console` for an interactive prompt that will
allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.
To release a new version, update the version number in `version.rb`,
and then run `bundle exec rake release`, which will create a git
tag for the version, push git commits and tags, and push the `.gem`
file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/kalopa/sgslib.
This project is intended to be a safe, welcoming space for
collaboration, and contributors are expected to adhere to the
[Contributor Covenant](http://contributor-covenant.org) code of
conduct.

## License

The gem is available as open source under the terms of the
[GPL v2 License](http://opensource.org/licenses/gpl-2.0).
