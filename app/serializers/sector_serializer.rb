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
class SectorSerializer
  include JSONAPI::Serializer
  attributes :name
end
