# frozen_string_literal: true

require "active_support/core_ext/module/delegation"
require "active_support/core_ext/object/deep_dup"
require "active_support/core_ext/object/with_options"
require "active_support/hash_with_indifferent_access"
require "active_support/descendants_tracker"
require "active_support/deprecation"
require "active_support/deprecator"

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
  class Error < StandardError; end
  class UnknownPropertyError < Error; end
  class KeyNotFoundError < Error; end
  class PropertyAlreadyExists < Error; end
  class InvalidPropertyError < Error; end
  class MethodAlreadyExistsError < Error; end
end
