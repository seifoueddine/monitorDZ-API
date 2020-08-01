class Medium < ApplicationRecord
    has_many :media_sectors
    has_many :sectors, through: :media_sectors
end
