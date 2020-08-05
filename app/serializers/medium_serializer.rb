class MediumSerializer
  include FastJsonapi::ObjectSerializer
  attributes :name, :media_type, :orientation
  has_many :media_sectors
  has_many :sectors, through: :media_sectors
end
