# frozen_string_literal: true

# == Schema Information
#
# Table name: media
#
#  id           :bigint           not null, primary key
#  name         :string
#  media_type   :string
#  orientation  :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  url_crawling :string
#  last_article :string
#  avatar       :string
#  zone         :string
#  language     :string
#  tag_status   :boolean
#
class Medium < ApplicationRecord
  validates :name, format: {with: /[a-zA-Z]/}
  validates :url_crawling, format: {with: /[a-zA-Z]/}
  has_many :media_sectors
  has_many :sectors, through: :media_sectors
  has_many :campaign_media
  has_many :campaigns, through: :campaign_media
  has_many :articles
  mount_uploader :avatar, IconUploader
end
