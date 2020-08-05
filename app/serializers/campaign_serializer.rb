class CampaignSerializer
  include FastJsonapi::ObjectSerializer
  attributes :name, :start_date, :end_date
  has_many :campaign_media
  has_many :campaigns, through: :campaign_media
  has_many :campaign_sectors
  has_many :campaigns, through: :campaign_sectors
end
