# frozen_string_literal: true

class Author < ApplicationRecord
  validates_uniqueness_of :name
  has_many :articles, dependent: :delete_all
end
