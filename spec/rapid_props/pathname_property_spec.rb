# frozen_string_literal: true

require "spec_helper"

RSpec.describe RapidProps::PathnameProperty, type: :property do
  describe "parse" do
    it "allows strings" do
      expect(property.parse("foo")).to eql(Pathname.new("foo"))
    end

    it "allows numbers" do
      expect(property.parse(1)).to eql(Pathname.new("1"))
      expect(property.parse(3.14)).to eql(Pathname.new("3.14"))
    end

    it "allows symbols" do
      expect(property.parse(:foo)).to eql(Pathname.new("foo"))
    end

    it "allows pathnames" do
      expect(property.parse(Pathname.new("/foo"))).to eql(Pathname.new("/foo"))
    end

    it "raises an error when given an array" do
      expect{property.parse([])}.to raise_error(RapidProps::InvalidPropertyError)
    end

    it "freezes the pathname so its value cannot be changed without the parent object knowing" do
      s = String.new("foo") # use constructor to avoid `frozen_string_literal`
      expect(property.parse(s).frozen?).to eql(true)
    end

    describe "prepended_slash" do
      it "allows automatically removing it" do
        prop = property(prepended_slash: false)
        expect(prop.parse(Pathname.new("/foo"))).to eql(Pathname.new("foo"))
        expect(prop.parse(Pathname.new("foo"))).to eql(Pathname.new("foo"))
      end

      it "allows requiring it" do
        prop = property(prepended_slash: true)
        expect(prop.parse(Pathname.new("foo"))).to eql(Pathname.new("/foo"))
        expect(prop.parse(Pathname.new("/foo"))).to eql(Pathname.new("/foo"))
      end

      it "allows not caring either way" do
        prop = property(prepended_slash: nil)
        expect(prop.parse(Pathname.new("/foo"))).to eql(Pathname.new("/foo"))
        expect(prop.parse(Pathname.new("foo"))).to eql(Pathname.new("foo"))
      end
    end

    describe "appended_slash" do
      it "allows automatically removing it" do
        prop = property(appended_slash: false)
        expect(prop.parse(Pathname.new("foo/"))).to eql(Pathname.new("foo"))
        expect(prop.parse(Pathname.new("foo"))).to eql(Pathname.new("foo"))
      end

      it "allows requiring it" do
        prop = property(appended_slash: true)
        expect(prop.parse(Pathname.new("foo"))).to eql(Pathname.new("foo/"))
        expect(prop.parse(Pathname.new("foo/"))).to eql(Pathname.new("foo/"))
      end

      it "allows not caring either way" do
        prop = property(appended_slash: nil)
        expect(prop.parse(Pathname.new("foo/"))).to eql(Pathname.new("foo/"))
        expect(prop.parse(Pathname.new("foo"))).to eql(Pathname.new("foo"))
      end
    end
  end

  describe "serialize" do
    it "serializes strings" do
      expect(property.serialize(Pathname.new("foo"))).to eql("foo")
    end
  end

  describe "build" do
    let(:instance) { builder.klass.new }

    it "defines a property on the class" do
      builder.pathname(:name)
      expect(builder.klass.properties.keys).to match_array(%i[name])
    end

    it "defines a reader and a writer method" do
      builder.pathname(:name)
      expect{instance.name = "foo"}.to change{instance.name}.from(nil).to(Pathname.new("foo"))
    end

    it "automatically validates presence of the property when null: false" do
      builder.pathname(:name, null: false)
      expect(instance.valid?).to eql(false)
      expect(instance.errors.details[:name]).to eql([{ error: :blank }])
    end
  end
end
