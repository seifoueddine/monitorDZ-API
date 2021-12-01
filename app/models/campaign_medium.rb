# frozen_string_literal: true

class CampaignMedium < ApplicationRecord
  belongs_to :medium
  belongs_to :campaign
end
