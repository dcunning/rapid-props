# frozen_string_literal: true

require "spec_helper"

RSpec.describe RapidProps::EmbedsOneProperty, type: :property do
  describe "implicitly defined class" do
    class self::Page
      include RapidProps::Container

      properties do |p|
        p.embeds_one :author do |o|
          o.string :name
          o.boolean :enabled
        end
      end
    end

    let(:klass) { self.class::Page }
    let(:property) { klass.find_property(:author) }
    let(:author) { klass::Author.new(name: "Dan Cunning") }
    let(:page) { klass.new(author: author) }

    it "makes the instance nil by default" do
      expect(klass.new.author).to be_nil
    end

    it "supports hashes" do
      expect(property.parse({ name: "Dan Cunning" })).to eql(author)
    end

    it "supports parsing the type itself" do
      expect(property.parse(author)).to eql(author)
    end

    it "recognizes `true` as initializing an empty object" do
      expect(property.parse(true)).to eql(self.class::Page.new)
    end

    it "recognizes `false` as leaving the relationship blank" do
      expect(property.parse(false)).to be_nil
    end

    it "supports writing some properties w/o overwriting others" do
      page.author = { enabled: true, name: "Test" }

      expect{
        page.author = { name: "Foo" }
      }.to change{page.author.name}.from("Test").to("Foo")
      .and not_change{page.author.enabled?}
    end

    it "knows setting the child to nil removes the relationship" do
      page.author = nil
      expect(page.author).to be_nil
    end

    it "knows setting the child to false removes the relationship" do
      page.author = false
      expect(page.author).to be_nil
    end

    it "doesn't change any properties when writing `true`" do
      page.author = { enabled: true, name: "Test" }

      expect{
        page.author = true
      }.to not_change{page.author.name}
      .and not_change{page.author.enabled?}
    end

    it "supports strong parameters" do
      expect(property.strong_parameters).to eql(author_properties: [:name, :enabled])
    end

    it "defines an attributes accessor" do
      expect(page.author_properties).to eql(name: "Dan Cunning", enabled: nil)
    end

    it "defines a build_* method for creating an instance" do
      page = klass.new
      page.build_author(name: "Dan Cunning")
      expect(page.author.name).to eql("Dan Cunning")
    end

    it "describes itself in JSON" do
      expect(property.as_json).to eql(
        "type" => "embeds_one",
        "id" => "author",
        "embedded" => [{
          "type" => "string",
          "id" => "name",
        },{
          "type" => "boolean",
          "id" => "enabled",
        }],
      )
    end

    it "raises an error when the hash has invalid values" do
      expect{property.parse({ email: "dan@rapidlybuilt.com" })}.to raise_error(RapidProps::UnknownPropertyError)
    end

    it "raises an error when given an array" do
      expect{property.parse([])}.to raise_error(RapidProps::InvalidPropertyError)
    end

    it "doesn't add the type when serializing" do
      expect(property.serialize(author)).to eql("name" => "Dan Cunning", "enabled" => nil)
    end

    it "freezes the embeds_many when its container is frozen" do
      page.freeze
      expect{page.author = { name: "John Steinbeck" } }.to raise_error(FrozenError)
      expect{author.name = "John Steinbeck"}.to raise_error(FrozenError)
    end
  end

  describe "null: false" do
    class self::Page
      include RapidProps::Container

      properties do |p|
        p.embeds_one :author, null: false do |o|
          o.string :name, default: ->(c) { c.parent.default_author_name }
        end
      end

      def default_author_name
        "John Doe"
      end
    end

    it "automatically initializes the instance" do
      expect(self.class::Page.new.author.class).to eql(self.class::Page::Author)
    end

    it "exposes #parent on the child" do
      expect(self.class::Page.new.author.name).to eql("John Doe")
    end
  end

  describe "polymorphic type" do
    class self::Page
      include RapidProps::Container

      properties do |p|
        p.embeds_one :author, polymorphic: true
      end
    end

    class self::Author
      include RapidProps::Container

      properties do |p|
        p.string :name
      end
    end

    class self::Blogger
      include RapidProps::Container

      properties do |p|
        p.string :website
      end
    end

    let(:property) { self.class::Page.find_property(:author) }
    let(:author) { self.class::Author.new(name: "Dan Cunning") }
    let(:blogger) { self.class::Blogger.new(website: "https://rapidlybuilt.com") }

    it "parses many different classes" do
      expect(property.parse({ type: self.class::Author.name, name: "Dan Cunning" })).to eql(author)
      expect(property.parse({ type: self.class::Blogger.name, website: "https://rapidlybuilt.com" })).to eql(blogger)
    end

    it "adds the type attribute when serializing" do
      expect(property.serialize(author)).to eql(
        "type" => self.class::Author.name,
        "name" => "Dan Cunning",
      )
    end
  end

  describe "explicitly defined class" do
    class self::Person < RapidProps::EmbeddedChild
      properties do |p|
        p.string :name
      end
    end

    class self::Page
      include RapidProps::Container

      properties do |p|
        p.embeds_one :author, class_name: module_parent::Person.name
      end
    end

    it "doesn't define a new subclass" do
      expect(self.class::Page.properties[:author].child_class).to eql(self.class::Person)
    end

    it "doesn't allow adding properties to an existing class" do
      expect{
        self.class::Page.properties do |p|
          p.embeds_one :editor, class_name: self.class::Person.name do |o|
            o.string :email
          end
        end
      }.to raise_error(ArgumentError, "you cannot use class_name with a new properties block")
    end
  end

  describe "implicitly defined class with a superclass" do
    class self::Person < RapidProps::EmbeddedChild
      properties do |p|
        p.string :name
      end
    end

    class self::Page
      include RapidProps::Container

      properties do |p|
        p.embeds_one :author, superclass: module_parent::Person do |o|
          o.integer :pages_count, default: 0, null: false
        end
      end
    end

    it "defines a new subclass of the superclass" do
      expect(self.class::Page::Author.superclass).to eql(self.class::Person)
    end

    it "doesn't modify superclass' properties" do
      expect(self.class::Person.properties.map(&:id)).to eql(%i[name])
      expect(self.class::Page::Author.properties.map(&:id)).to eql(%i[name pages_count])
    end
  end

  describe "polymorphic w/ required superclass" do
    class self::Person
      include RapidProps::Container

      properties do |p|
        p.string :name
      end
    end

    class self::Author < self::Person
      properties do |p|
        p.string :pen_name
      end
    end

    class self::Rando
      include RapidProps::Container

      properties do |p|
        p.string :name
      end
    end

    class self::Page
      include RapidProps::Container

      properties do |p|
        p.embeds_one :author, polymorphic: true, superclass: module_parent::Person
      end
    end

    let(:property) { self.class::Page.find_property(:author) }
    let(:author) { self.class::Author.new(name: "Dan Cunning", pen_name: "DC") }
    let(:blogger) { self.class::Blogger.new(name: "Dan Cunning", website: "https://rapidlybuilt.com") }

    it "parses many different classes" do
      expect(property.parse({ type: self.class::Author.name, name: "Dan Cunning", pen_name: "DC" })).to eql(author)
    end

    it "errors when not given a subclass" do
      expect{property.parse({ type: self.class::Rando.name, name: "Dan Cunning" })}.to raise_error(RapidProps::InvalidPropertyError)
    end

    it "allows writing the embedded property with an instance of the superclass" do
      page = self.class::Page.new(author: self.class::Person.new(name: "John"))
      expect(page.author.class).to eql(self.class::Person)
    end

    it "allows writing the embedded property with an instance of the superclass' subclass" do
      page = self.class::Page.new(author: self.class::Author.new(name: "John"))
      expect(page.author.class).to eql(self.class::Author)
    end
  end

  describe "external class definition" do
    class self::Page
      include RapidProps::Container

      properties do |p|
        p.embeds_one :author, class_name: "#{module_parent_name}::Author", polymorphic: true
      end
    end

    class self::Author
      include RapidProps::Container

      properties do |p|
        p.string :name
      end
    end

    let(:property) { self.class::Page.find_property(:author) }
    let(:author) { self.class::Author.new(name: "Dan Cunning") }

    it "parses hashes into instances" do
      expect(property.parse({ name: "Dan Cunning" })).to eql(author)
    end
  end

  describe "valid?" do
    class self::Page
      include RapidProps::Container

      properties do |p|
        p.embeds_one :author do |o|
          o.string :email, null: false
        end

        p.embeds_many :tags do |o|
          o.string :name, null: false
        end
      end
    end

    let(:page) { self.class::Page.new(author: {}) }

    it "is invalid when an embedded child isn't valid" do
      expect(page.valid?).to eql(false)
    end

    it "knows the exact child that isn't valid" do
      page.valid?
      expect(page.errors.details[:author]).to eql([{ error: :invalid }])
      expect(page.errors.full_messages).to include("Author is invalid")
    end

    it "is valid when all embedded children are valid" do
      page.author.email = "dan@rapidlybuilt.com"
      expect(page.valid?).to eql(true)
    end
  end

  describe "referencing parent from child" do
    class self::Page
      include RapidProps::Container

      properties do |p|
        p.string :id
        p.embeds_one :tag do |o|
          o.string :id, default: ->(c) { c.parent.id + "-tag" }
        end
      end
    end

    it "allows referencing parent properties from the children" do
      expect(self.class::Page.new(id: "demo", tag: {}).tag.id).to eql("demo-tag")
    end
  end

  describe "proc class name" do
    class self::Page
      include RapidProps::Container

      properties do |p|
        p.string :id
        p.embeds_one :author, class_name: -> { "#{module_parent_name}::Author".constantize }
      end
    end

    class self::Author < RapidProps::EmbeddedChild
      properties do |p|
        p.string :name
      end
    end

    it "supports a proc as the class name" do
      expect(self.class::Page.new(id: "demo", author: { name: "Dan" }).author.class).to eql(self.class::Author)
    end
  end
end
