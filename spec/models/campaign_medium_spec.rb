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
require 'rails_helper'

RSpec.describe CampaignMedium, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
