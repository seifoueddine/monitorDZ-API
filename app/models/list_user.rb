# frozen_string_literal: true

class ListUser < ApplicationRecord
  belongs_to :user
  has_many :list_articles
  has_many :articles, through: :list_articles
end
