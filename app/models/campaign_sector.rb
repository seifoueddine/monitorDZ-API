# frozen_string_literal: true

class CampaignSector < ApplicationRecord
  belongs_to :sector
  belongs_to :campaign
end
