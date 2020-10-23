class AddImagePathToList < ActiveRecord::Migration[6.0]
  def change
    add_column :list_users, :image, :string

  end
end
