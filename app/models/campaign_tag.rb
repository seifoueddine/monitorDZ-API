# frozen_string_literal: true

class CampaignTag < ApplicationRecord
  belongs_to :tag
  belongs_to :campaign
end
