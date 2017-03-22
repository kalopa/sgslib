require 'spec_helper'

describe SGS do
  it 'has a version number' do
    expect(SGS::VERSION).not_to be nil
  end

  it 'creates a useful GPS record' do
    gps = SGS::GPS.new
    expect(gps.time.year).to eq(2000)
  end

  it 'can save a GPS record in Redis' do
    gps = SGS::GPS.new
    gps.time = Time.now
    gps.sog = 6.0
    gps.cmg = 1.4
    gps.location = SGS::Location.parse_str("53N,9W")
    expect(gps.save).to be true
  end
  
  it 'can retrieve a GPS record from Redis' do
    gps = SGS::GPS.load
    expect(gps.time.year).to eq(Time.now.year)
  end
end
