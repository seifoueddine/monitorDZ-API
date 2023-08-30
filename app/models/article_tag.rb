# frozen_string_literal: true

# == Schema Information
#
# Table name: article_tags
#
#  id          :bigint           not null, primary key
#  tag_id      :integer
#  article_id  :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  campaign_id :integer
#  slug_id     :integer

class ArticleTag < ApplicationRecord
  belongs_to :article
  belongs_to :tag
end
