#!/usr/bin/env ruby
#
$: << "lib"
require 'sgslib.rb'

samples = [
  ["41°24'12.2\"N 2°10'26.5\"E", 41.4033889, 2.17402778],
  ["41°24'12.2\"N, 2°10'26.5\"E", 41.4033889, 2.17402778],
  ["41.40338, 2.17403", 41.40338, 2.17403],
  ["41 24.2028, 2 10.4418 w", 41.40338, -2.17403],
  ["53 9.395 N, 9 2.119 W", 53.1565833, -9.03531667],
  ["53 9.395'S, 9 2.119'W", -53.1565833, -9.03531667],
  ["53.18279N, 9.29182E", 53.18279, 9.29182],
  ["53.18279 n, 9.29182 w", 53.18279, -9.29182],
  ["53.18279, -9.29182", 53.18279, -9.29182]
]

puts "Parse inputs..."
samples.each do |sample|
  loc = SGS::Location.parse(sample[0])
  puts loc.to_s(format: :dmm)
  err1 = (sample[1] - loc.latitude_d).abs
  err2 = (sample[2] - loc.longitude_d).abs
  if err1 > 1e-6 or err2 > 1e-6
    puts "Test failed."
    exit 1
  end
end

puts "Show outputs..."
loc = SGS::Location.new
loc.parse_hash({"latitude" => "53 10.1818N",
       "longitude" => "9 4.2456W"})
puts loc.to_s
puts loc.to_s(format: :dd)
puts loc.to_s(format: :dmm)
puts loc.to_s(format: :dms)
exit 0
