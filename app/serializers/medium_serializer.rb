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
class MediumSerializer
  include JSONAPI::Serializer
  attributes :name, :media_type, :orientation, :url_crawling, :last_article,
             :avatar, :language, :zone, :tag_status
  has_many :media_sectors
  has_many :sectors, through: :media_sectors
end
