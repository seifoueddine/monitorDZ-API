# frozen_string_literal: true

# == Schema Information
#
# Table name: campaigns
#
#  id         :bigint           not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  slug_id    :bigint           not null
#  start_date :datetime
#  end_date   :datetime
#
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
