class AddCompaignToArticleTag < ActiveRecord::Migration[6.1]
  def change
    add_column :article_tags, :campaign_id, :integer
  end
end
