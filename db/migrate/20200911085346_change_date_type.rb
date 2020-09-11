class ChangeDateType < ActiveRecord::Migration[6.0]
  def change
    remove_column  :articles, :date_published
  end
end
