# frozen_string_literal: true

# == Schema Information
#
# Table name: articles
#
#  id               :bigint           not null, primary key
#  title            :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  body             :text
#  author           :string
#  media_tags       :string
#  url_image        :string
#  language         :string
#  medium_id        :bigint           not null
#  url_article      :string
#  category_article :string
#  is_tagged        :boolean
#  author_id        :bigint
#  status           :string
#  date_published   :datetime
#  image            :string
#
require 'rails_helper'

RSpec.describe Article, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
