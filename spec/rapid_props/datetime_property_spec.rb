# frozen_string_literal: true

require "spec_helper"

RSpec.describe RapidProps::DatetimeProperty, type: :property do
  let(:now) { Time.now }
  let(:now_s) { "2021-04-09 15:20:18 -0400" }

  describe "parse" do
    it "allows Time objects" do
      expect(property.parse(now)).to eql(now)
    end

    it "converts DateTime objects to Time objects" do
      dt = DateTime.now
      expect(property.parse(dt)).to eql(dt.to_time)
      expect(property.parse(dt).class).to eql(Time)
    end

    it "casts strings to times" do
      expect(property.parse(now_s)).to eql(Time.parse(now_s))
    end

    it "raises an error when given date format" do
      expect{property.parse("2019-01-03")}.to raise_error(RapidProps::InvalidPropertyError)
    end

    it "raises an error when given invalid times" do
      expect{property.parse("2019-13-30 1:00pm")}.to raise_error(RapidProps::InvalidPropertyError)
    end

    it "raises an error when given a number" do
      expect{property.parse(1)}.to raise_error(RapidProps::InvalidPropertyError)
    end
  end

  describe "serialize" do
    it "serializes times" do
      expect(property.serialize(Time.parse(now_s))).to eql(now_s)
    end
  end

  describe "build" do
    let(:instance) { builder.klass.new }

    it "defines a property on the class" do
      builder.datetime(:created_at)
      expect(builder.klass.properties.keys).to match_array(%i[created_at])
    end

    it "defines a reader and a writer method" do
      builder.datetime(:created_at)
      expect{instance.created_at = now}.to change{instance.created_at}.from(nil).to(now)
    end
  end
end
