class ListUserSerializer
  include JSONAPI::Serializer
  attributes :name, :articles
  belongs_to :user
  has_many :list_articles
  has_many :articles, through: :list_articles
end
