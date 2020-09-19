class AddMediaToAuthor < ActiveRecord::Migration[6.0]
  def change
    add_column :authors, :medium_id, :integer
  end
end
