class CampaignSerializer
  include JSONAPI::Serializer
  attributes :name, :start_date, :end_date, :slug_id, :media, :slug, :tags
  has_many :campaign_media
  has_many :media, through: :campaign_media
  has_many :campaign_sectors
  has_many :sectors, through: :campaign_sectors
  belongs_to :slug
  has_many :campaign_tags
  has_many :tags, through: :campaign_tags
end
