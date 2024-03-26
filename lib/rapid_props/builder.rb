# frozen_string_literal: true

module RapidProps
  # Provides syntatic sugar for defining all the property implementations in this gem.
  # An instance of this class is passed to the code defining properties.
  #
  # To support only a subset of property types offered by this library:
  #
  #   class MyBuilder
  #     include RapidProps::BuilderSupport
  #
  #     # only the ones you want
  #     include RapidProps::DateProperty::Builder
  #   end
  #
  # To add support for new property types while retaining all the existing properties defined
  # by this gem:
  #
  #   class MyBuilder < RapidProps::Builder
  #     include MyPropertyType::Builder
  #   end
  class Builder
    include BuilderSupport

    include BooleanProperty::Builder
    include DateProperty::Builder
    include DatetimeProperty::Builder
    include DecimalProperty::Builder
    include DurationProperty::Builder
    include EmbedsManyProperty::Builder
    include EmbedsOneProperty::Builder
    include EnumProperty::Builder
    include HashProperty::Builder
    include IntegerProperty::Builder
    include PathnameProperty::Builder
    include StringProperty::Builder
    include SymbolProperty::Builder
    include UrlProperty::Builder
  end
end
