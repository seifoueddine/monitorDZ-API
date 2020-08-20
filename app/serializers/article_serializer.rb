class ArticleSerializer
  include FastJsonapi::ObjectSerializer
  attributes :title, :date_published, :author, :body,
             :media_tags, :language, :url_image, :url_article, :category_article, :is_tagged
  belongs_to :medium
  has_many :article_tags
  has_many :tags, through: :article_tags
end
