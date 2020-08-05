class AddColumnToCampaings < ActiveRecord::Migration[6.0]
  def change
    add_reference :campaigns, :slug, null: false, foreign_key: true
    add_column :campaigns, :start_date, :timestamp
    add_column :campaigns, :end_date, :timestamp
  end
end
