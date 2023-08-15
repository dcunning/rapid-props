# frozen_string_literal: true

module RapidProps
  # Base class for embeds_one instances.
  class EmbeddedChild
    include Container

    attr_reader :parent

    def initialize(parent: nil, **kargs)
      super(**kargs)
      @parent = parent
    end
  end
end
