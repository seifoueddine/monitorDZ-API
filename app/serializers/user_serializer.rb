class UserSerializer
  include FastJsonapi::ObjectSerializer
  # set_key_transform :camel
  attributes :name, :created_at, :updated_at, :role, :avatar, :slug_id, :email

  belongs_to :slug
end
