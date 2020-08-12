class ChangeColumnsNamesAndAddMoreColumnToArtciles < ActiveRecord::Migration[6.0]
  def change
    rename_column :articles, :name, :title
    rename_column :articles, :date_article, :date_published
    add_column :articles, :article_tags, :string
  end
end
