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
require 'rails_helper'

RSpec.describe MediaSector, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
