# frozen_string_literal: true

unless RUBY_ENGINE == "truffleruby"
  require "simplecov"
  SimpleCov.start do
    add_filter "/spec/"
  end
end

require "rapid_props"
require "debug" unless ENV.key?("GITHUB_ACTION")

# ensure simplecov isn't missing anything
Zeitwerk::Loader.eager_load_all

Dir[File.join(".", "spec", "support", "**", "*.rb")].sort.each { |f| require f }
RSpec::Matchers.define_negated_matcher :not_change, :change
RSpec::Matchers.define_negated_matcher :not_include, :include
