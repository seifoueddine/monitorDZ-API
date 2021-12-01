# frozen_string_literal: true

class SlugSerializer
  include JSONAPI::Serializer
  attributes :name
end
