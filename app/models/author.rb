# frozen_string_literal: true

# == Schema Information
#
# Table name: authors
#
#  id             :bigint           not null, primary key
#  name           :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  medium_id      :integer
#  articles_count :integer
#
class Author < ApplicationRecord
 # validates_uniqueness_of :name
  #validates :name, format: {with: /[a-zA-Z]/}
  has_many :articles, dependent: :delete_all
end
