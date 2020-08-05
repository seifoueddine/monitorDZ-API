class CreateCampaignSectors < ActiveRecord::Migration[6.0]
  def change
    create_table :campaign_sectors do |t|
      t.integer :campaign_id
      t.integer :sector_id

      t.timestamps
    end
  end
end
