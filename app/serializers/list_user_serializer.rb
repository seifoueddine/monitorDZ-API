# frozen_string_literal: true

class ListUserSerializer
  include JSONAPI::Serializer
  attributes :name, :articles, :created_at, :image
  belongs_to :user
  has_many :list_articles
  has_many :articles, through: :list_articles
end
