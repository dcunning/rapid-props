# frozen_string_literal: true

require "spec_helper"

RSpec.describe RapidProps::DurationProperty, type: :property do
  let(:twenty_seconds) { ActiveSupport::Duration.seconds(20) }
  let(:fifteen_minutes) { ActiveSupport::Duration.minutes(15) }
  let(:twelve_hours) { ActiveSupport::Duration.hours(12) }
  let(:thirty_days) { ActiveSupport::Duration.days(30) }
  let(:five_months) { ActiveSupport::Duration.months(5) }
  let(:two_years) { ActiveSupport::Duration.years(2) }
  let(:one_year) { ActiveSupport::Duration.years(1) }

  describe "parse" do
    it "recognizes durations" do
      expect(property.parse(twenty_seconds)).to eql(twenty_seconds)
    end

    it "recognizes seconds" do
      expect(property.parse("20 seconds")).to eql(twenty_seconds)
    end

    it "recognizes minutes" do
      expect(property.parse("15 minutes")).to eql(fifteen_minutes)
    end

    it "recognizes hours" do
      expect(property.parse("12 hours")).to eql(twelve_hours)
    end

    it "recognizes days" do
      expect(property.parse("30 days")).to eql(thirty_days)
    end

    it "recognizes months" do
      expect(property.parse("5 months")).to eql(five_months)
    end

    it "recognizes years" do
      expect(property.parse("2 years")).to eql(two_years)
    end

    it "allows commas years" do
      expect(property.parse("2,000 years")).to eql(ActiveSupport::Duration.years(2000))
    end

    it "recognizes the singular version of all units" do
      expect(property.parse("1 year")).to eql(ActiveSupport::Duration.years(1))
    end

    it "recognizes fractions of a unit" do
      expect(property.parse("3.5 hours")).to eql(ActiveSupport::Duration.hours(3.5))
    end

    it "raises an error when given invalid format" do
      expect{property.parse("20.seconds")}.to raise_error(RapidProps::InvalidPropertyError)
    end

    it "raises an error when given invalid unit" do
      expect{property.parse("20 corks")}.to raise_error(RapidProps::InvalidPropertyError)
    end

    it "raises an error when given a number" do
      expect{property.parse(1)}.to raise_error(RapidProps::InvalidPropertyError)
    end

    it "doesn't recognize durations with multiple units (yet!)" do
      expect{property.parse(two_years + five_months)}.to raise_error(RapidProps::InvalidPropertyError)
    end
  end

  describe "serialize" do
    it "processes seconds" do
      expect(property.serialize(twenty_seconds)).to eql("20 seconds")
    end

    it "removes the 's' for singlular amounts" do
      expect(property.serialize(one_year)).to eql("1 year")
    end
  end

  describe "build" do
    let(:instance) { builder.klass.new }

    it "defines a property on the class" do
      builder.duration(:expires_in)
      expect(builder.klass.properties.keys).to match_array(%i[expires_in])
    end

    it "defines a reader and a writer method" do
      builder.duration(:expires_in)
      expect{instance.expires_in = twenty_seconds}.to change{instance.expires_in}.from(nil).to(twenty_seconds)
    end
  end
end
