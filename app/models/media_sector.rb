# frozen_string_literal: true

# == Schema Information
#
# Table name: media_sectors
#
#  id         :bigint           not null, primary key
#  medium_id  :integer
#  sector_id  :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class MediaSector < ApplicationRecord
  belongs_to :sector
  belongs_to :medium
end
