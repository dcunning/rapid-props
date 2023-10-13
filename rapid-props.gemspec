# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("lib", __dir__)
require "rapid_props/version"

Gem::Specification.new do |gem|
  gem.name     = "rapid-props"
  gem.license  = "MIT"
  gem.version  = RapidProps::VERSION

  gem.author   = "Dan Cunning"
  gem.email    = "dan@rapidlybuilt.com"
  gem.homepage = "https://rapidlybuilt.com"
  gem.summary  = "Defining a schema for attributes in a Plain-Old-Ruby-Object"
  gem.required_ruby_version = ">= 3.1"

  gem.description = gem.summary

  gem.files = Dir["**/*"].grep(%r{^(README|bin/|data/|ext/|lib/|spec/|test/)})

  gem.metadata = {
    "rubygems_mfa_required" => "true",
  }

  gem.add_dependency "activemodel", ">= 7.1"
  gem.add_dependency "zeitwerk", "~> 2.4"
end
