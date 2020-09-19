class Article < ApplicationRecord
  searchkick
  #after_commit :indexing
  scope :search_import, -> { includes(:author, :medium, :tags) }
  has_many :article_tags
  has_many :tags, through: :article_tags
  belongs_to :author
  belongs_to :medium

=begin
  def search_data
    attributes.merge(tags: tags.map(&:name))
  end
=end


    # protected

  #def indexing
  # Article.reindex
  #  Medium.reindex
  # end


end
