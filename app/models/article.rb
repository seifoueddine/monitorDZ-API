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
class Article < ApplicationRecord
  validates :ave, inclusion: { in: %w[NEGATIVE POSITIVE NEUTRAL], allow_nil: true }
  searchkick match: :word,
             suggest: %i[title body media_area medium_type author_name tag_name],
             merge_mappings: true,
             mappings: {
               properties: {
                 body: {
                   type: 'text',
                   fields: {
                     analyzed: {
                       type: 'text',
                       analyzer: 'searchkick_index'
                     },
                     suggest: {
                       type: 'text',
                       analyzer: 'searchkick_suggest_index'
                     }
                   }
                 }
               }
             }
  #   after_commit :reindex_data
  #
  #   def reindex_data
  #     author.reindex
  #     tags.reindex
  #     medium.reindex
  #   end

  # after_commit :indexing
  # acts_as_authorable
  scope :search_import, -> { includes(:author, :medium, :tags) }
  has_many :article_tags, dependent: :destroy
  has_many :tags, through: :article_tags
  belongs_to :author
  belongs_to :medium
  has_many :list_articles, dependent: :destroy
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
      language: language,
      ave: ave
    }
  end

  # protected

  # def indexing
  # Article.reindex
  #  Medium.reindex
  # end
end
