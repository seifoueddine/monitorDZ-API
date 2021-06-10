class ArticleSerializer
  #include JSONAPI::Serializer
  include JSONAPI::Serializer
  attributes :title, :date_published, :author, :body, :medium,
             :media_tags, :language, :url_image, :url_article, :tags,
             :category_article, :is_tagged, :status, :image
  belongs_to :medium
  belongs_to :author
  has_many :article_tags
  has_many :tags, through: :article_tags
end
