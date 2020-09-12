class CampaignTag < ApplicationRecord
  belongs_to :tag
  belongs_to :campaign
end
