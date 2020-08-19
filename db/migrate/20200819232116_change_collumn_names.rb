class ChangeCollumnNames < ActiveRecord::Migration[6.0]
  def change
    rename_column :articles, :article_tags, :media_tags
    add_column :articles, :is_tagged, :boolean
  end
end
