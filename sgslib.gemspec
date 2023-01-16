# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sgs/version'

Gem::Specification.new do |spec|
  spec.name          = "sgslib"
  spec.version       = SGS::VERSION
  spec.authors       = ["Dermot Tynan"]
  spec.email         = ["dtynan@kalopa.com"]

  spec.summary       = %q{Sailboat Guidance System}
  spec.description   = %q{Sailboat Guidance System - an autonomous navigation and control system for robotic sailboats.}
  spec.homepage      = "http://github.com/kalopa/sgslib"
  spec.license       = "GPL-2.0"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "https://rubygems.org"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = [
    "Gemfile",
    "LICENSE",
    "Rakefile",
    "bin/console",
    "README.md",
    "sgslib.gemspec",
  ] + Dir.glob("exe/*") + Dir.glob("lib/**/*")
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 1.9.2'

  spec.add_development_dependency "bundler", "~> 2.2"
  spec.add_development_dependency "rake", ">= 12.3.3"
  spec.add_development_dependency "rspec", "~> 3.0"

  spec.add_runtime_dependency "redis", "~> 4.7"
  spec.add_runtime_dependency "serialport", "~> 1.3"
  spec.add_runtime_dependency "msgpack", "~> 1.3"
  spec.add_runtime_dependency "json"
  spec.add_runtime_dependency "securerandom"
  spec.add_runtime_dependency "yaml"
end
