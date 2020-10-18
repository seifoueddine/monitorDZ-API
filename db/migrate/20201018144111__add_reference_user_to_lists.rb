class AddReferenceUserToLists < ActiveRecord::Migration[6.0]
  def change
    add_reference :list_users, :user, foreign_key: true
  end
end
