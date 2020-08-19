class ArticleSerializer
  include FastJsonapi::ObjectSerializer
  attributes :title, :date_published, :author, :body,
             :article_tags, :language, :url_image, :url_article, :category_article
  belongs_to :medium
end
