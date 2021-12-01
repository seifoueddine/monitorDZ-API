# frozen_string_literal: true

class Slug < ApplicationRecord
  validates_uniqueness_of :name
  has_many :users
  has_many :campaigns
end
