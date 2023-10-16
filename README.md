# Rapid Props
[![Tests](https://github.com/dcunning/rapid-props/workflows/Tests/badge.svg)](https://github.com/dcunning/rapid-props/actions?query=workflow%3ATests)

`rapid-props` defines a class' attributes in a syntax similar to Ruby on Rails' `create_table`.

## Table of Contents

- [Getting Started](#getting-started)
- [Types](#types)
- [Usage](#usage)
- [Contributing](#contributing)
- [Versioning](#versioning)
- [License](#license)

## Getting Started

Start by including `rapid-props` in your Gemfile:

```ruby
gem 'rapid-props', git: 'https://github.com/dcunning/rapid-props.git', branch: 'master'
```

Then run `bundle install`.

## Types

- `boolean` true or false
- `date`
- `datetime`
- `decimal` a number with precision and scale
- `duration` a length of time
- `embeds_many` an array of objects
- `embeds_one` a single instance of an object
- `enum` a value from a set of acceptable values
- `hash` a collection of key/value pairs
- `integer`
- `string`
- `url`

## Usage

```ruby
class BlogPost
  include RapidProps::Container

  properties do |p|
    p.string :slug, null: false
    p.string :title, null: false
    p.enum :category, choices: %w[ living politics technology ]
    p.date :publish_date
    p.boolean :has_comments, default: false, null: false

    p.embeds_many :tags do |o|
      o.string :slug, null: false
    end

    p.embeds_one :author do |o|
      o.string :name, null: false
    end
  end
end

# initializes an object w/ all associations
BlogPost.new(
  slug: "dropdown-tutorial",
  title: "Tutorial: Dropdowns",
  category: "technology",
  publish_date: "2023-10-16",
  tags: [{ slug: "ruby-on-rails" }],
  author: { name: "John Doe" },
)

# raises RapidProps::UnknownPropertyError
BlogPost.new(foo: "bar")
```

### allow_writing_invalid_properties

By default set to `false` meaning the property's setter method will raise an error
when given an invalid property value. When set to `true`, invalid property values will
not raise an error inside the setter method, but will note an error when validating
the record like `ActiveRecord`.

```ruby
# all raise RapidProps::InvalidPropertyError
BlogPost.new(slug: ["about-us"])
BlogPost.new(category: "unknown")
BlogPost.new(tags: "ruby-on-rails")

BlogPost.allow_writing_invalid_properties = true

post = BlogPost.new(slug: ["about-us"])
post.slug
# => ["about-us"]
post.valid?
# => false
post.errors.details
# => { slug: [{ error: :invalid_property }]}
```

## Contributing

If you have problems, please create a [GitHub Issue](/.github/ISSUE_TEMPLATE/bug-report.md).

## Versioning

`rapid-props` follows Semantic Versioning 2.0 as defined at https://semver.org.

## License

This code is free to use under the terms of the MIT license.
