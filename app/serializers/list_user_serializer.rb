class ListUserSerializer
  include JSONAPI::Serializer
  attributes :name
  belongs_to :user
end
