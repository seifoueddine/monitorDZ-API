# frozen_string_literal: true

# == Schema Information
#
# Table name: campaign_sectors
#
#  id          :bigint           not null, primary key
#  campaign_id :integer
#  sector_id   :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class CampaignSectorSerializer
  include JSONAPI::Serializer
  attributes
end
