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
class Slug < ApplicationRecord
  validates_uniqueness_of :name
  has_many :users
  has_many :campaigns
end
