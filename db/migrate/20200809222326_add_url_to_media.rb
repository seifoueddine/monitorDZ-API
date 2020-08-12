class AddUrlToMedia < ActiveRecord::Migration[6.0]
  def change
    add_column :media, :url_crawling, :string
  end
end
