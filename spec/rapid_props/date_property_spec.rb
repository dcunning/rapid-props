# frozen_string_literal: true

require "spec_helper"

RSpec.describe RapidProps::DateProperty, type: :property do
  let(:today) { Date.today }

  describe "parse" do
    it "allows Date objects" do
      expect(property.parse(today)).to eql(today)
    end

    it "casts YYYY-MM-DD" do
      expect(property.parse("2019-01-03")).to eql(Date.new(2019, 1, 3))
    end

    it "raises an error when given invalid date formats" do
      expect{property.parse("2019-1-3")}.to raise_error(RapidProps::InvalidPropertyError)
      expect{property.parse("01-04-2019")}.to raise_error(RapidProps::InvalidPropertyError)
    end

    it "raises an error when given invalid dates" do
      expect{property.parse("2019-13-30")}.to raise_error(RapidProps::InvalidPropertyError)
      expect{property.parse("2019-01-32")}.to raise_error(RapidProps::InvalidPropertyError)
    end

    it "raises an error when given a Time object" do
      expect{property.parse(Time.now)}.to raise_error(RapidProps::InvalidPropertyError)
    end
  end

  describe "serialize" do
    it "serializes dates" do
      expect(property.serialize(Date.parse("2021-04-01"))).to eql("2021-04-01")
    end
  end

  describe "build" do
    let(:instance) { builder.klass.new }

    it "defines a property on the class" do
      builder.date(:start_date)
      expect(builder.klass.properties.keys).to match_array(%i[start_date])
    end

    it "defines a reader and a writer method" do
      builder.date(:start_date)
      expect{instance.start_date = today}.to change{instance.start_date}.from(nil).to(today)
    end
  end
end
