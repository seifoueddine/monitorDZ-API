class Campaign < ApplicationRecord
    belongs_to :slug
    has_many :campaign_sectors
    has_many :sectors, through: :campaign_sectors
end
