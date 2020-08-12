class RenameColumnArticle < ActiveRecord::Migration[6.0]
  def change
    rename_column :articles, :url_crawling, :url_image
  end
end
