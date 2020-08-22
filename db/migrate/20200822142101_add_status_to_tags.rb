class AddStatusToTags < ActiveRecord::Migration[6.0]
  def change
    add_column :tags, :status, :boolean
  end
end
