class TagSerializer
  include JSONAPI::Serializer
  attributes :name, :status
end
