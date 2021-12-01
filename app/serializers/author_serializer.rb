# frozen_string_literal: true

class AuthorSerializer
  include JSONAPI::Serializer
  attributes :name, :medium_id, :articles_count
end
