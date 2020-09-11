class AddDateToArticles < ActiveRecord::Migration[6.0]
  def change
    add_column :articles, :date_published, :datetime

  end
end
