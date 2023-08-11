require "rapid_props/rspec/properties_support"

RSpec.configure do |config|
  config.include RapidProps::RSpec::PropertiesSupport, type: :property
end
