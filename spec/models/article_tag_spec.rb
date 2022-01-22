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
#
require 'rails_helper'

RSpec.describe ArticleTag, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
