# frozen_string_literal: true

# == Schema Information
#
# Table name: campaign_media
#
#  id          :bigint           not null, primary key
#  campaign_id :integer
#  medium_id   :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class CampaignMediumSerializer
  include JSONAPI::Serializer
  attributes
end
