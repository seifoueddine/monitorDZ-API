class CreateCampaignMedia < ActiveRecord::Migration[6.0]
  def change
    create_table :campaign_media do |t|
      t.integer :campaign_id
      t.integer :medium_id

      t.timestamps
    end
  end
end
