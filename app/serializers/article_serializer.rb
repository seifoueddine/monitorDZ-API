# frozen_string_literal: true

# == Schema Information
#
# Table name: articles
#
#  id               :bigint           not null, primary key
#  title            :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  body             :text
#  author           :string
#  media_tags       :string
#  url_image        :string
#  language         :string
#  medium_id        :bigint           not null
#  url_article      :string
#  category_article :string
#  is_tagged        :boolean
#  author_id        :bigint
#  status           :string
#  date_published   :datetime
#  image            :string
#
class ArticleSerializer
  # include JSONAPI::Serializer
  include JSONAPI::Serializer
  attributes :title, :date_published, :author, :body, :medium,
             :media_tags, :language, :url_image, :url_article, :tags,
             :category_article, :is_tagged, :status, :image, :ave
  belongs_to :medium
  belongs_to :author
  has_many :article_tags
  has_many :tags, through: :article_tags
end
