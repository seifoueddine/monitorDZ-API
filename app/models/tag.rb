class Tag < ApplicationRecord
  has_many :article_tags
  has_many :articles, through: :article_tags
  has_many :campaign_tags
  has_many :campaigns, through: :campaign_tags
  after_commit :reindex_article

  def reindex_article
    Article.reindex
  end
end
