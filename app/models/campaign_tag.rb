# frozen_string_literal: true

# == Schema Information
#
# Table name: campaign_tags
#
#  id          :bigint           not null, primary key
#  campaign_id :integer
#  tag_id      :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class CampaignTag < ApplicationRecord
  belongs_to :tag
  belongs_to :campaign
end
