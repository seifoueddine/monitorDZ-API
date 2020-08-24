class Medium < ApplicationRecord
  has_many :media_sectors
  has_many :sectors, through: :media_sectors
  has_many :campaign_media
  has_many :campaigns, through: :campaign_media
  has_many :articles
end
