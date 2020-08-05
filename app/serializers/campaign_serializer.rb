class CampaignSerializer
  include FastJsonapi::ObjectSerializer
  attributes :name, :start_date, :end_date, :slug_id
  has_many :campaign_media
  has_many :media, through: :campaign_media
  has_many :campaign_sectors
  has_many :sectors, through: :campaign_sectors
  belongs_to :slug
end
