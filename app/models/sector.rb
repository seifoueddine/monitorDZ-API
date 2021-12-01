# frozen_string_literal: true

class Sector < ApplicationRecord
  has_many :media_sectors
  has_many :media, through: :media_sectors
  has_many :campaign_sectors
  has_many :campaigns, through: :campaign_sectors
end
