class ArticleTag < ApplicationRecord
  belongs_to :article
  belongs_to :tag



  #after_commit :reindex_article

  #def reindex_article
  #  Article.reindex
  #end



end
