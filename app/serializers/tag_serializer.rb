# frozen_string_literal: true

# == Schema Information
#
# Table name: tags
#
#  id         :bigint           not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  status     :boolean
#
class TagSerializer
  include JSONAPI::Serializer
  attributes :name, :status
end
