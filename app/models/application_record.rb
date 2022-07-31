# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
  scope :name_like, ->(value){ where(['lower(name) like ? ',"%#{value.downcase}%"])}
end
