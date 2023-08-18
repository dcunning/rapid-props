# frozen_string_literal: true

require "spec_helper"

RSpec.describe RapidProps::Property, type: :property do
  class PropertyImpl < RapidProps::Property
    def parse(value, context: nil)
      value
    end

    def serialize(value)
      value
    end
  end

  it "requires subclasses to implement #parse" do
    expect{property.parse(nil)}.to raise_error(NotImplementedError)
  end

  it "requires subclasses to implement #serialize" do
    expect{property.serialize(nil)}.to raise_error(NotImplementedError)
  end

  it "supports default values specified as procs" do
    prop = PropertyImpl.new(:enabled, klass: property.klass, default: ->(v) { "foo" })
    expect(prop.default_for(nil)).to eql("foo")
  end

  it "supports strong parameters" do
    expect(property(:enabled).strong_parameters).to eql(:enabled)
  end

  it "converts to a hash" do
    expect(property(:enabled).to_hash).to eql(
      type: nil,
      id: :enabled,
    )
  end

  it "specifies a default value Proc when converting to a hash" do
    expect(property(:enabled, default: ->(v) { "foo" }).to_hash).to eql(
      type: nil,
      id: :enabled,
      default: { type: "proc" },
    )
  end

  describe "default option" do
    let(:klass) {
      Class.new do
        include RapidProps::Container

        properties do |p|
          p.string :id, null: false
        end
      end
    }
    let(:my_post) { klass.new(id: "my-post") }
    let(:title_property) { klass.find_property(:title) }

    it "supports nil default, though it's not necessary" do
      klass.class_eval do
        properties do |p|
          p.string :title, default: nil
        end
      end

      expect(my_post.title).to be nil
      expect(title_property.to_hash.keys).not_to include(:default)
    end

    it "supports a symbol that references an instance method" do
      klass.class_eval do
        properties do |p|
          p.string :title, default: :generate_title
        end

        def generate_title
          id.gsub("-", " ")
        end
      end

      expect(my_post.title).to eql("my post")
      expect(title_property.to_hash[:default]).to eql(type: "method")
    end

    it "supports explicit default values" do
      klass.class_eval do
        properties do |p|
          p.string :title, default: "Untitled"
        end
      end

      expect(my_post.title).to eql("Untitled")
      expect(title_property.to_hash[:default]).to eql("Untitled")
    end

    it "supports a zero-argument Proc" do
      klass.class_eval do
        properties do |p|
          p.string :title, default: -> { "Untitled" }
        end
      end

      expect(my_post.title).to eql("Untitled")
      expect(title_property.to_hash[:default]).to eql(type: "proc")
    end

    it "supports a Proc with a context" do
      klass.class_eval do
        properties do |p|
          p.string :title, default: ->(r) { r.id.gsub("-", " ") }
        end
      end

      expect(my_post.title).to eql("my post")
    end

    it "allow default to return an invalid value, but it makes the record invalid" do
      klass.class_eval do
        properties do |p|
          p.string :title, default: :default_title, null: false
        end

        def default_title
          nil
        end
      end

      expect(my_post.title).to eql(nil)
      expect(my_post.valid?).to be false
      expect(my_post.errors.details[:title]).to include(error: :blank)
    end

    it "automatically detects a default_:property_id method on the instance" do
      klass.class_eval do
        properties do |p|
          p.string :title, null: false
        end

        def default_title
          "title"
        end
      end

      expect(my_post.title).to eql("title")
    end

    it "allows changing the default value of a property inside of a subclass" do
      subclass = Class.new(klass) do
        change_property_default :id, "test"
      end

      expect(subclass.new.id).to eql("test")
    end

    it "allows changing the default value to a proc" do
      subclass = Class.new(klass) do
        change_property_default :id, -> { "test" }
      end

      expect(subclass.new.id).to eql("test")
      expect(klass.new.id).to eql(nil)
    end

    it "raises an error when calling #change_property_default with an unknown property id" do
      expect{
        Class.new(klass) do
          change_property_default :foo, "test"
        end
      }.to raise_error(RapidProps::UnknownPropertyError)
    end

    it "raises an error when calling #change_property_default with an invalid property value" do
      expect{
        Class.new(klass) do
          change_property_default :id, []
        end
      }.to raise_error(RapidProps::InvalidPropertyError)
    end

    it "raises InvalidPropertyError when the default function provides an invalid value" do
      klass.class_eval do
        properties do |p|
          p.string :title, default: :default_title, null: false
        end

        def default_title
          []
        end
      end

      expect{my_post.title}.to raise_error(RapidProps::InvalidPropertyError)
    end
  end
end
