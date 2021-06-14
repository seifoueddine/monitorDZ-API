class Article < ApplicationRecord
  searchkick match: :word,
            suggest: %i[title body media_area medium_type author_name tag_name]


=begin

  after_commit :reindex_data

  def reindex_data
    author.reindex
    tags.reindex
    medium.reindex
  end
=end


  #after_commit :indexing
  # acts_as_authorable
  scope :search_import, -> { includes(:author, :medium, :tags) }
  has_many :article_tags
  has_many :tags, through: :article_tags
  belongs_to :author
  belongs_to :medium

  has_many :list_articles
  has_many :list_users, through: :list_articles
  mount_uploader :image, ImageUploader

  def search_data
    {
      title: title,
      body: body,
      author_name: author.name,
      tag_name: tags.map(&:name),
      medium_type: medium.media_type,
      media_area: medium.zone,
      medium_id: medium_id,
      date_published: date_published,
      is_tagged: is_tagged,
      author_id: author_id,
      language: language
    }
  end



    # protected

  #def indexing
  # Article.reindex
  #  Medium.reindex
  # end


end
