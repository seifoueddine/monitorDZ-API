# frozen_string_literal: true

# == Schema Information
#
# Table name: media
#
#  id           :bigint           not null, primary key
#  name         :string
#  media_type   :string
#  orientation  :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  url_crawling :string
#  last_article :string
#  avatar       :string
#  zone         :string
#  language     :string
#  tag_status   :boolean
#
require 'rails_helper'

RSpec.describe Medium, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
