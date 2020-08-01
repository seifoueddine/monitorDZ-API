class Sector < ApplicationRecord
    has_many :media_sectors
    has_many :media, through: :media_sectors
end
