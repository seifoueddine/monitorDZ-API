class AddAveToArticles < ActiveRecord::Migration[6.1]
  def change
    add_column :articles, :ave, :string, default: "NEUTRAL"
  end
end
