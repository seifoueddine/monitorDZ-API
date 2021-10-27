class AuthorSerializer
  include JSONAPI::Serializer
  attributes :name, :medium_id
end
