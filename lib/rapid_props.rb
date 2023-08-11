# frozen_string_literal: true

require "active_support/core_ext/module/delegation"
require "active_support/core_ext/object/deep_dup"
require "active_support/core_ext/object/with_options"
require "active_support/hash_with_indifferent_access"
require "active_support/descendants_tracker"

require "active_support/concern"
require "active_model/serialization"
require "active_model/serializers/json"
require "active_model"

require "zeitwerk"

lib_directory = File.expand_path(__dir__)

loader = Zeitwerk::Loader.new
loader.push_dir(lib_directory)
loader.ignore(File.join(lib_directory, "rapid-props.rb"))
loader.ignore(File.join(lib_directory, "rapid_props/rspec/properties_support.rb"))
loader.ignore(File.join(lib_directory, "rapid_props/version.rb"))
loader.setup # ready!

module RapidProps
  # Superclass for all errors raised by this gem.
  class Error < StandardError; end

  # Raised when looking up a non-existant property +id+.
  class UnknownPropertyError < Error; end

  # Raised when finding an instance inside an +embeds_many+ association.
  class KeyNotFoundError < Error; end

  # Raised when trying to add a property to a class that's already defined that
  # property +id+
  class PropertyAlreadyExists < Error; end

  # Raised when a property rejects a value based on the property's configuration.
  class InvalidPropertyError < Error; end

  # Raised when defining a property but the +method_name+ already exists on the
  # parent class.
  class MethodAlreadyExistsError < Error; end
end
