---
name: Bug Report
about: Create a bug report
title: "Issue title goes here"
labels: "🐞 Issue: Bug"
assignees: ''

---

## Describe the bug
A clear and concise description of what the bug is.

## To Reproduce
Describe a way to reproduce your bug. To get the gem version, run `RapidProps::VERSION`.

Use the reproduction script below to reproduce the issue:

```
# frozen_string_literal: true

require "bundler/inline"

gemfile(true) do
  source "https://rubygems.org"

  git_source(:github) { |repo| "https://github.com/#{repo}.git" }

  gem "rapid-props", git: "https://github.com/dcunning/rapid-props.git", branch: "master"
  gem "minitest"
end

require "minitest/autorun"

class BlogPost
  include RapidProps::Container

  properties do |p|
    p.string :title, null: false
  end
end

class BugTest < Minitest::Test
  def test_property
    # CHANGEME - Reproduce the issue here. Here's an example:
    @obj = BlogPost.new(title: "Hello World")
    assert @obj.title == "Greetings!"
  end
end

```

## Expected behavior
A clear and concise description of what you expected to happen.

## Additional context
Add any other additional information about the problem here.
