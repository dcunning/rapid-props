# frozen_string_literal: true

require "spec_helper"

RSpec.describe RapidProps::Container do
  class self::Post
    include RapidProps::Container

    properties do |p|
      p.string :id, null: false
    end
  end

  let(:klass) { self.class::Post }
  let(:my_post) { klass.new(id: "my-post") }

  it "allows retrieving the property values in Hash form" do
    expect(my_post.properties).to eql(id: "my-post")
  end

  it "allows setting property values" do
    my_post.properties = { id: "another-post" }
    expect(my_post.id).to eql("another-post")
  end

  it "knows when a property exists" do
    expect(my_post.property?(:id)).to be true
  end

  it "knows when a property doesn't exist" do
    expect(my_post.property?(:foo)).to be false
  end

  it "allows reading/writing a specific property" do
    my_post.id = "another-post"
    expect(my_post.id).to eql("another-post")
  end

  it "throws an error when reading a property that doesn't exist" do
    expect{my_post.read_property(:title)}.to raise_error(RapidProps::UnknownPropertyError)
  end

  it "throws an error when writing a property that doesn't exist" do
    expect{my_post.write_property(:title, "Foo")}.to raise_error(RapidProps::UnknownPropertyError)
  end

  it "defines a #properties method on the class that describes the schema" do
    expect(klass.properties.map(&:id)).to eql(%i[id])
  end

  it "knows when a property value is valid" do
    expect(my_post.valid?).to be(true)
  end

  it "knows when a property value is invalid" do
    expect(klass.new.valid?).to be(false)
  end

  describe "method name conflicts" do
    class self::BlogPost < self::Post
      properties do |p|
        p.date :date, null: false
      end
    end

    let(:subclass) { self.class::BlogPost }

    it "raises an error when defining a property that is already a method on the class" do
      expect{
        subclass.properties do |p|
          p.string :send, null: false
        end
      }.to raise_error(RapidProps::MethodAlreadyExistsError)
    end

    it "doesn't an error if you give it a different method name" do
      expect{
        subclass.properties do |p|
          p.string :send, null: false, method_name: :send_property
        end
      }.to change{subclass.instance_methods.include?(:send_property)}.from(false).to(true)
    end
  end

  describe "inspect" do
    class self::BlogPost < self::Post
      properties do |p|
        p.integer :views_count, default: 0, null: false
      end
    end

    let(:subclass) { self.class::BlogPost }

    it "includes explicitly set properties, not defaults" do
      expect(subclass.new.inspect).not_to include("views_count")
      expect(subclass.new(views_count: 0).inspect).to include("views_count")
    end
  end

  describe "to_hash" do
    class self::BlogPost < self::Post
      properties do |p|
        p.embeds_one :author do |o|
          o.string :name
        end
      end
    end

    let(:subclass) { self.class::BlogPost }

    it "hasherizes children" do
      expect(subclass.new(author: { name: "John" }).to_hash).to eql(id: nil, author: { name: "John" })
    end
  end

  describe "inheritance" do
    class self::BlogPost < self::Post
      properties do |p|
        p.date :date, null: false
      end
    end

    let(:subclass) { self.class::BlogPost }

    it "brings the properties of the parent to the child" do
      expect(subclass.properties.map(&:id)).to eql(%i[id date])
    end

    it "doesn't alter the properties of the super class" do
      expect(klass.properties.map(&:id)).to eql(%i[id])
    end
  end

  describe "allow_writing_invalid_properties" do
    class self::BlogPost < self::Post
      properties do |p|
        p.enum :category, choices: %w[ living politics technology ]
      end

      def reload
        reset_invalid_properties
      end
    end

    let(:subclass) { self.class::BlogPost }
    let(:invalid_post) { subclass.new(id: []) }

    before { subclass.allow_writing_invalid_properties = true }

    it "knows that it allows writing invalid properties" do
      expect(subclass.allow_writing_invalid_properties?).to eql(true)
      expect(invalid_post.allow_writing_invalid_properties?).to eql(true)
    end

    it "doesn't raise an error when initializing the invalid object" do
      expect{ invalid_post }.not_to raise_error
    end

    it "returns the invalid property" do
      expect(invalid_post.id).to eql([])
    end

    it "knows the object is invalid and why" do
      expect(invalid_post.valid?).to eql(false)
      expect(invalid_post.errors.details[:id]).to include(error: :invalid_property)
    end

    it "allows subclasses to reset invalid properties" do
      invalid_post.reload
      expect(invalid_post.valid?).to eql(false)
      expect(invalid_post.errors.details[:id]).not_to include(error: :invalid_property)
    end

    it "uses a different error symbol when subclassing InvalidPropertyError" do
      invalid_post.category = "unknown"
      expect(invalid_post.valid?).to eql(false)
      expect(invalid_post.errors.details[:category]).to include(error: :unknown_enum)
    end
  end

  describe "validate" do
    class self::BlogPost < self::Post
      properties do |p|
        p.date :date, null: false
      end
    end

    let(:subclass) { self.class::BlogPost }

    it "knows when a property is missing" do
      post = subclass.new
      expect(post.valid?).to be false
      expect(post.errors.details[:date]).to include(error: :blank)
    end

    it "raises an InvalidPropertyError when given a bad type" do
      expect{subclass.new(id: [])}.to raise_error(RapidProps::InvalidPropertyError)
    end
  end

  describe "freeze" do
    class self::Page
      include RapidProps::Container

      properties do |p|
        p.string :id, null: false
      end
    end

    let(:instance) { self.class::Page.new }

    it "knows whether it's frozen" do
      expect{instance.freeze}.to change{instance.frozen?}.from(false).to(true)
    end

    it "throws a FrozenError when writing properties on a frozen instance" do
      instance.id = "foo"
      instance.freeze
      expect{instance.id = "bar"}.to raise_error(FrozenError)
    end

    it "always freezes string properties without having to call freeze on the parent" do
      instance.id = String.new("foo")
      expect{instance.id.sub!("f", "b")}.to raise_error(FrozenError)
    end
  end

  describe "flat_errors" do
    class self::Page
      include RapidProps::Container

      properties do |p|
        p.string :id, null: false

        p.embeds_one :author do |o|
          o.string :email, null: false
        end

        p.embeds_many :tags do |o|
          o.string :name, null: false
        end

        p.embeds_many :ads, key: :slug do |o|
          o.string :slug, null: false
          o.string :title, null: false
        end
      end
    end

    let(:page) { self.class::Page.new(author: {}) }

    it "flattens top-level error details" do
      page.valid?
      expect(page.flat_errors.details[:id]).to eql([{ error: :blank }])
    end

    it "flattens embeds_one error details" do
      page.valid?
      expect(page.flat_errors.details[:"author.email"]).to eql([{ error: :blank }])
      expect(page.flat_errors.details[:author]).to eql([])
    end

    it "flattens embeds_many error details" do
      page.tags.new
      page.valid?
      expect(page.flat_errors.details[:"tags[0].name"]).to eql([{ error: :blank }])
      expect(page.flat_errors.details[:tags]).to eql([])
    end

    it "flattens top-level error full messages" do
      page.valid?
      expect(page.flat_errors.full_messages).to include("Id can't be blank")
    end

    it "flattens embeds_one error details" do
      page.valid?
      expect(page.flat_errors.full_messages).to include("Author email can't be blank")
      expect(page.flat_errors.full_messages).not_to include("Author is invalid")
    end

    it "flattens embeds_many error details" do
      page.tags.new
      page.valid?
      expect(page.flat_errors.full_messages).to include("Tags[0] name can't be blank")
      expect(page.flat_errors.full_messages).not_to include("Tags is invalid")
    end

    it "uses the key instead of the index for #embeds_many when they are indexed by key" do
      page.properties = { ads: [{}] }
      expect(page.valid?).to be false
      expect(page.flat_errors.full_messages).to include("Ads[0] slug can't be blank")

      page.ads[0].slug = "foo-bar"
      expect(page.flat_errors.full_messages).to include("Ads[foo-bar] title can't be blank")
    end
  end
end
