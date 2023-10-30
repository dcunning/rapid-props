# frozen_string_literal: true

require "spec_helper"

RSpec.describe RapidProps::StringProperty, type: :property do
  describe "parse" do
    it "allows strings" do
      expect(property.parse("foo")).to eql("foo")
    end

    it "allows numbers" do
      expect(property.parse(1)).to eql("1")
      expect(property.parse(3.14)).to eql("3.14")
    end

    it "allows symbols" do
      expect(property.parse(:foo)).to eql("foo")
    end

    it "allows pathnames" do
      expect(property.parse(Pathname.new("/foo"))).to eql("/foo")
    end

    it "raises an error when given an array" do
      expect{property.parse([])}.to raise_error(RapidProps::InvalidPropertyError)
    end

    it "freezes the string so its value cannot be changed without the parent object knowing" do
      s = String.new("foo") # use constructor to avoid `frozen_string_literal`
      expect(property.parse(s).frozen?).to eql(true)
    end
  end

  describe "serialize" do
    it "serializes strings" do
      expect(property.serialize("foo")).to eql("foo")
    end
  end

  describe "build" do
    let(:instance) { builder.klass.new }

    it "defines a property on the class" do
      builder.string(:name)
      expect(builder.klass.properties.keys).to match_array(%i[name])
    end

    it "defines a reader and a writer method" do
      builder.string(:name)
      expect{instance.name = "foo"}.to change{instance.name}.from(nil).to("foo")
    end

    it "automatically validates presence of the property when null: false" do
      builder.string(:name, null: false)
      expect(instance.valid?).to eql(false)
      expect(instance.errors.details[:name]).to eql([{ error: :blank }])
    end
  end

  describe "array of strings" do
    class self::Page
      include RapidProps::Container

      properties do |p|
        p.strings :tags
      end
    end

    let(:klass) { self.class::Page }
    let(:property) { klass.find_property(:tags) }
    let(:tags) { %w[programming ruby-on-rails] }

    it "supports parsing" do
      expect(property.parse(tags)).to eql(tags)
    end

    it "accepts them in the constructor" do
      expect(klass.new(tags: tags).tags).to eql(tags)
    end

    it "doesn't define the attributes helper" do
      expect(klass.new.respond_to?(:tags_properties)).to be false
    end
  end
end
