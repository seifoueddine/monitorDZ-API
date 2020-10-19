class CreateListArticles < ActiveRecord::Migration[6.0]
  def change
    create_table :list_articles do |t|
      t.integer :article_id
      t.integer :list_user_id

      t.timestamps
    end
  end
end
