class Sector < ApplicationRecord
    has_many :media_sectors
    has_many :media, through: :media_sectors
    has_many :campaign_sectors
    has_many :campaigns, through: :campaign_sectors

    before_destroy :check

def check
  status = true
  if self.media_sectors.count > 0
    self.errors[:deletion_status] = 'Cannot delete sector with active media in it.'
    status = false
  else
    self.errors[:deletion_status] = 'OK.'
  end
  status
end


end
