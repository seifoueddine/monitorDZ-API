class ArticleSerializer
  include FastJsonapi::ObjectSerializer
  attributes :title, :date_published, :author, :body,
             :article_tags, :language, :url_image

end
