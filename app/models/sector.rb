# frozen_string_literal: true

# == Schema Information
#
# Table name: sectors
#
#  id         :bigint           not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Sector < ApplicationRecord
  has_many :media_sectors
  has_many :media, through: :media_sectors
  has_many :campaign_sectors
  has_many :campaigns, through: :campaign_sectors
end
