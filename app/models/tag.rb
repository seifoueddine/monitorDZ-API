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
class Tag < ApplicationRecord
  has_many :article_tags
  has_many :articles, through: :article_tags
  has_many :campaign_tags
  has_many :campaigns, through: :campaign_tags
end
