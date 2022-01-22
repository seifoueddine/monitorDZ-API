# frozen_string_literal: true

# == Schema Information
#
# Table name: slugs
#
#  id         :bigint           not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class SlugSerializer
  include JSONAPI::Serializer
  attributes :name
end
