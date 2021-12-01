# frozen_string_literal: true

class AddLastArticleToMedia < ActiveRecord::Migration[6.0]
  def change
    add_column :media, :last_article, :string
  end
end
