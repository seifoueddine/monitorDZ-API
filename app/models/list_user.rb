# frozen_string_literal: true

# == Schema Information
#
# Table name: list_users
#
#  id         :bigint           not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :bigint
#  image      :string
#
class ListUser < ApplicationRecord
  validates :name, format: {with: /[a-zA-Z]/}
  belongs_to :user
  has_many :list_articles
  has_many :articles, through: :list_articles
end
