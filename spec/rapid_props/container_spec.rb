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
  end

  describe "errors.full_messages" do
    class self::BlogPost < self::Post
      properties do |p|
        p.date :date, null: false

        p.embeds_one :author do |o|
          o.string :name, null: false
          o.embeds_one :site do |n|
            n.string :name, null: false
          end
        end

        p.embeds_many :tags do |o|
          o.string :name, null: false
        end
      end
    end

    let(:subclass) { self.class::BlogPost }
    let(:post) { subclass.new }

    it "allows you to change the base path" do
      post.errors.base_path = "post"
      expect(post.valid?).to be false
      expect(post.errors.full_messages_with_paths).to include("post.date can't be blank")
    end

    it "displays the property path instead of the i18n'ed name" do
      expect(post.valid?).to be false
      expect(post.errors.full_messages_with_paths).to not_include("Date can't be blank")
        .and include("blog_post.date can't be blank")
    end

    it "displays an #embeds_one path in the error message" do
      post.properties = { author: {} }
      expect(post.valid?).to be false
      expect(post.errors.full_messages_with_paths).to not_include("Author is invalid")
        .and not_include("blog_post.author is invalid")
        .and include("blog_post.author.name can't be blank")
    end

    it "displays children of children paths" do
      post.properties = { author: { site: {} } }
      expect(post.valid?).to be false
      expect(post.errors.full_messages_with_paths).to include("blog_post.author.site.name can't be blank")
    end

    it "displays the index of #embeds_many relationships" do
      post.properties = { tags: [{}] }
      expect(post.valid?).to be false
      expect(post.errors.full_messages_with_paths).to include("blog_post.tags[0].name can't be blank")
    end

    it "displays the key instead of the index for #embeds many when they are indexed by key" do
      subclass.properties do |p|
        p.embeds_many :ads, key: :slug do |o|
          o.string :slug, null: false
          o.string :title, null: false
        end
      end

      post.properties = { ads: [{}] }
      expect(post.valid?).to be false
      expect(post.errors.full_messages_with_paths).to include("blog_post.ads[0].slug can't be blank")

      post.ads[0].slug = "foo-bar"
      expect(post.errors.full_messages_with_paths).to include(%(blog_post.ads[foo-bar].title can't be blank))
    end
  end
end
