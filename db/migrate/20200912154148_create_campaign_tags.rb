class CreateCampaignTags < ActiveRecord::Migration[6.0]
  def change
    create_table :campaign_tags do |t|
      t.integer :campaign_id
      t.integer :tag_id

      t.timestamps
    end
  end
end
