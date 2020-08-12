class MediumSerializer
  include FastJsonapi::ObjectSerializer
  attributes :name, :media_type, :orientation, :url_crawling, :last_article
  has_many :media_sectors
  has_many :sectors, through: :media_sectors
end
