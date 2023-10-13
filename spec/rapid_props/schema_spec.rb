# frozen_string_literal: true

require "spec_helper"

RSpec.describe RapidProps::Schema do
  class self::Post
    include RapidProps::Container

    properties do |p|
      p.string :id, null: false
      p.embeds_one :author do |o|
        o.string :name, null: false
      end
      p.embeds_many :tags do |o|
        o.string :slug, null: false
      end
    end
  end

  let(:klass) { self.class::Post }

  it "raises an error when setting a bad key type" do
    expect{klass.properties[1] = klass.properties[:id]}.to raise_error(ArgumentError)
  end

  it "raises an error when finding an unknown key" do
    expect{klass.find_property(:name)}.to raise_error(RapidProps::UnknownPropertyError)
  end

  it "converts properties to strong_parameters" do
    expect(klass.properties.strong_parameters).to eql(
      [:id, { author_properties: [:name], tags_properties: [:slug] }]
    )
  end

  it "serializes properties into hash" do
    expect(klass.properties.as_json).to eql([{
      "type" => "string",
      "id" => "id",
      "required" => true,
    }, {
      "type" => "embeds_one",
      "id" => "author",
      "embedded" => [{
        "type" => "string",
        "id" => "name",
        "required" => true,
      }],
    }, {
      "type" => "embeds_many",
      "id" => "tags",
      "embedded" => [{
        "type" => "string",
        "id" => "slug",
        "required" => true,
      }],
    }])
  end

  describe "#except_unknown" do
    it "removes all unknown properties from a hash" do
      expect(klass.properties.except_unknown(id: "foo", title: "Foo")).to eql(id: "foo")
    end

    it "removes unknown properties from embeds_one hashes" do
      expect(klass.properties.except_unknown(id: "foo", author: { name: "John", email: "foo" })).to eql(
        id: "foo", author: { name: "John" },
      )
    end

    it "removes unknown properties from embeds_many arrays" do
      expect(klass.properties.except_unknown(id: "foo", tags: [{ slug: "foo", title: "Foo" }])).to eql(
        id: "foo", tags: [{ slug: "foo" }],
      )
    end

    it "doesn't raise an error when given a non-array for embeds_one" do
      expect(klass.properties.except_unknown(id: "foo", author: "foo")).to eql(
        id: "foo", author: "foo",
      )
    end

    it "doesn't raise an error when given a non-array for embeds_many" do
      expect(klass.properties.except_unknown(id: "foo", tags: "foo")).to eql(
        id: "foo", tags: "foo",
      )
    end
  end
end
