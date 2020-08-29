class Article < ApplicationRecord
  searchkick
   after_commit :indexing
  scope :search_import, -> { includes(:author, :medium) }
  has_many :article_tags
  has_many :tags, through: :article_tags
  belongs_to :author
  belongs_to :medium


  protected

  def indexing
    Article.reindex
  end


end
