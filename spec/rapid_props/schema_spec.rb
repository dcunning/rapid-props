# frozen_string_literal: true

require "spec_helper"

RSpec.describe RapidProps::Schema do
  class self::Post
    include RapidProps::Container

    properties do |p|
      p.string :id, null: false
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
    expect(klass.properties.strong_parameters).to eql([:id, { tags_properties: [:slug] }])
  end

  it "removes all unknown properties from a hash" do
    expect(klass.properties.except_unknown(id: "foo", title: "Foo")).to eql(id: "foo")
  end

  it "serializes properties into hash" do
    expect(klass.properties.as_json).to eql([{
      "type" => "string",
      "id" => "id",
      "required" => true,
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
end
