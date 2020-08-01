class MediaSerializer
  include FastJsonapi::ObjectSerializer
  attributes :name, :type, :orientation
  has_many :media_sectors
  has_many :sectors, through: :media_sectors
end
