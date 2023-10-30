# frozen_string_literal: true

require "spec_helper"

RSpec.describe RapidProps::EmbedsOneProperty, type: :property do
  describe "implicitly defined class" do
    class self::Page
      include RapidProps::Container

      properties do |p|
        p.embeds_many :authors do |o|
          o.string :name
        end
      end
    end

    let(:klass) { self.class::Page }
    let(:property) { klass.find_property(:authors) }
    let(:author) { klass::Author.new(name: "Dan Cunning") }
    let(:page) { klass.new(authors: [author]) }

    it "supports arrays of hashes" do
      expect(property.parse([{ name: "Dan Cunning" }])).to eql([author])
    end

    it "supports parsing the type itself" do
      expect(property.parse([author])).to eql([author])
    end

    it "supports strong parameters" do
      expect(property.strong_parameters).to eql(authors_properties: [:name])
    end

    it "defines an attributes accessor" do
      expect(page.authors_properties).to eql([{ name: "Dan Cunning" }])
    end

    it "describes itself in JSON" do
      expect(property.as_json).to eql(
        "type" => "embeds_many",
        "id" => "authors",
        "embedded" => [{
          "type" => "string",
          "id" => "name",
        }],
      )
    end

    it "raises an error when the hash has invalid values" do
      expect{property.parse([{ email: "dan@rapidlybuilt.com" }])}.to raise_error(RapidProps::UnknownPropertyError)
    end

    it "raises an error when given a hash" do
      expect{property.parse({ "name" => "Dan Cunning" })}.to raise_error(RapidProps::InvalidPropertyError)
    end

    it "doesn't add the type when serializing" do
      expect(property.serialize([author])).to eql([{ "name" => "Dan Cunning" }])
    end

    it "freezes the embeds_many when its container is frozen" do
      page.freeze
      expect{page.authors = [{ name: "John Steinbeck" }] }.to raise_error(FrozenError)
      expect{author.name = "John Steinbeck"}.to raise_error(FrozenError)
    end
  end

  describe "implicitly defined class with a superclass" do
    class self::Comment < RapidProps::EmbeddedChild
      properties do |p|
        p.string :body
      end
    end

    class self::Page
      include RapidProps::Container

      properties do |p|
        p.embeds_many :comments, superclass: module_parent::Comment, polymorphic: true do |o|
          o.string :email, null: false
        end
      end
    end

    it "defines a new subclass of the superclass" do
      expect(self.class::Page::Comment.superclass).to eql(self.class::Comment)
    end

    it "doesn't modify superclass' properties" do
      expect(self.class::Comment.properties.map(&:id)).to eql(%i[body])
      expect(self.class::Page::Comment.properties.map(&:id)).to eql(%i[body email])
    end
  end

  describe "explicitly defined class" do
    class self::Comment < RapidProps::EmbeddedChild
      properties do |p|
        p.string :body
      end
    end

    class self::Page
      include RapidProps::Container

      properties do |p|
        p.embeds_many :comments, class_name: module_parent::Comment.name
      end
    end

    it "doesn't define a new subclass" do
      expect(self.class::Page.properties[:comments].child_class).to eql(self.class::Comment)
    end

    it "doesn't allow adding properties to an existing class" do
      expect{
        self.class::Page.properties do |p|
          p.embeds_many :additional_comments, class_name: self.class::Comment.name do |o|
            o.string :name
          end
        end
      }.to raise_error(ArgumentError, "you cannot use class_name with a new properties block")
    end
  end

  describe "polymorphic children" do
    class self::Page
      include RapidProps::Container

      properties do |p|
        p.embeds_many :authors, polymorphic: true
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

    let(:property) { self.class::Page.find_property(:authors) }
    let(:author) { self.class::Author.new(name: "Dan Cunning") }
    let(:blogger) { self.class::Blogger.new(website: "https://rapidlybuilt.com") }

    it "parses many different classes" do
      expect(property.parse([{
        type: self.class::Author.name,
        name: "Dan Cunning",
      }, {
        type: self.class::Blogger.name,
        website: "https://rapidlybuilt.com",
      }])).to eql([author, blogger])
    end

    it "adds the type attribute when serializing" do
      expect(property.serialize([author])).to eql([{
        "type" => self.class::Author.name,
        "name" => "Dan Cunning",
      }])
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
        p.embeds_many :authors, polymorphic: true, superclass: module_parent::Person
      end
    end

    let(:property) { self.class::Page.find_property(:authors) }
    let(:author) { self.class::Author.new(name: "Dan Cunning", pen_name: "DC") }
    let(:blogger) { self.class::Blogger.new(name: "Dan Cunning", website: "https://rapidlybuilt.com") }

    it "parses properly" do
      expect(property.parse([
        {type: self.class::Author.name, name: "Dan Cunning", pen_name: "DC"},
      ])).to eql([author])
    end

    it "errors when not given a subclass" do
      expect{property.parse([
        { type: self.class::Rando.name, name: "Dan Cunning" },
      ])}.to raise_error(RapidProps::InvalidPropertyError)
    end
  end

  describe "external class definition" do
    class self::Page
      include RapidProps::Container

      properties do |p|
        p.embeds_many :authors, class_name: "#{module_parent_name}::Author", polymorphic: true
      end
    end

    class self::Author
      include RapidProps::Container

      properties do |p|
        p.string :name
      end
    end

    let(:property) { self.class::Page.find_property(:authors) }
    let(:author) { self.class::Author.new(name: "Dan Cunning") }

    it "parses hashes into instances" do
      expect(property.parse([{ name: "Dan Cunning" }])).to eql([author])
    end
  end

  describe "organized by key instead of a flat array" do
    class self::Page
      include RapidProps::Container

      properties do |p|
        p.embeds_many :authors, key: :slug do |o|
          o.string :slug
          o.string :name
        end
      end
    end

    let(:property) { self.class::Page.find_property(:authors) }
    let(:author) { self.class::Page::Author.new(name: "Dan Cunning", slug: "dan") }
    let(:page) { self.class::Page.new(authors: [author]) }

    it "supports parsing a hash" do
      expect(property.parse({ "dan" => { name: "Dan Cunning" } })).to eql([author])
    end

    it "supports getting items by index" do
      expect(page.authors[0]).to eql(author)
    end

    it "supports finding by the key" do
      expect(page.authors.find("dan")).to eql(author)
    end

    it "raises an error finding an unknown key" do
      expect{page.authors.find("unknown")}.to raise_error(RapidProps::KeyNotFoundError)
    end

    it "adds sugar to reference keys" do
      expect(page.authors.dan).to eql(author)
      expect(page.authors.respond_to?(:dan)).to be_truthy
    end

    it "adds sugar to determine if a key is present" do
      expect(page.authors.dan?).to eql(true)
      expect(page.authors.steve?).to eql(false)
    end

    it "errors parsing a scalar" do
      expect{property.parse(3)}.to raise_error(RapidProps::InvalidPropertyError)
    end
  end

  describe "embedding scalars" do
    class self::Page
      include RapidProps::Container

      properties do |p|
        p.embeds_many :tags, class_name: "String", scalar: true
      end
    end

    let(:property) { self.class::Page.find_property(:tags) }
    let(:tags) { %w[programming ruby-on-rails] }

    it "supports parsing" do
      expect(property.parse(tags)).to eql(tags)
    end

    it "accepts them in the constructor" do
      expect(self.class::Page.new(tags: tags).tags).to eql(tags)
    end

    it "doesn't define the attributes helper" do
      expect(self.class::Page.new.respond_to?(:tags_properties)).to be false
    end
  end

  describe "adding new children" do
    class self::Page
      include RapidProps::Container

      properties do |p|
        p.embeds_many :tags do |o|
          o.string :id
        end
      end
    end

    let(:page) { self.class::Page.new }

    it "supports #new" do
      page.tags.new(id: "demo-tag")
      expect(page.tags.map(&:id)).to eql(%w[demo-tag])
    end

    it "supports #unshift" do
      page.tags.unshift(id: "demo-tag")
      expect(page.tags.map(&:id)).to eql(%w[demo-tag])
    end

    it "supports adding them via the constructor" do
      page = self.class::Page.new(tags: [{ id: "demo-tag" }])
      expect(page.tags.map(&:id)).to eql(%w[demo-tag])
    end

    it "supports adding them after using the constructor" do
      page = self.class::Page.new(tags: [])
      page.tags.new(id: "demo-tag")
      expect(page.tags.map(&:id)).to eql(%w[demo-tag])
    end

    it "raises an error when << is given a Hash" do
      expect{ page.tags << { id: "demo-tag" }}.to raise_error(ArgumentError)
    end
  end

  describe "valid?" do
    let(:invalid_page) { self.class::Page.new(tags: [{}]) }
    let(:valid_page) { self.class::Page.new(tags: [{ id: "test" }]) }

    class self::Page
      include RapidProps::Container

      properties do |p|
        p.embeds_many :tags do |o|
          o.string :id, null: false
        end
      end
    end

    it "is not invalid when there are no embedded children" do
      expect(self.class::Page.new.valid?).to eql(true)
    end

    it "is invalid when an embedded child isn't valid" do
      expect(invalid_page.valid?).to eql(false)
    end

    it "knows the exact child that isn't valid" do
      invalid_page.valid?
      expect(invalid_page.errors.details[:tags]).to eql([{ error: :invalid }])
    end

    it "is valid when all embedded children are valid" do
      expect(valid_page.valid?).to eql(true)
    end
  end

  describe "referencing parent from child" do
    class self::Page
      include RapidProps::Container

      properties do |p|
        p.string :id
        p.embeds_many :tags do |o|
          o.string :id, default: ->(c) { c.parent.id + "-tag" }
        end
      end
    end

    it "allows referencing parent properties from the children" do
      expect(self.class::Page.new(id: "demo", tags: [{}]).tags.first.id).to eql("demo-tag")
    end
  end
end
