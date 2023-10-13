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
gem 'rapid-props'
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
```

For a complete list of the generators, see [Generators](#generators).

#### A note about the Generators versions

If you get a `uninitialized constant Faker::[some_class]` error, your version of
the gem is behind main.

To make sure that your gem is the one
documented here, change the line in your Gemfile to:

```ruby
gem 'rapid-props', git: 'https://github.com/dcunning/rapid-props.git', branch: 'master'
```

## Contributing

If you have problems, please create a [GitHub Issue](/.github/ISSUE_TEMPLATE/bug-report.md).

## Versioning

`rapid-props` follows Semantic Versioning 2.0 as defined at https://semver.org.

## License

This code is free to use under the terms of the MIT license.
