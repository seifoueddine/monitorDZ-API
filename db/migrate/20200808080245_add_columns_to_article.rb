# frozen_string_literal: true

class AddColumnsToArticle < ActiveRecord::Migration[6.0]
  def change
    add_column :articles, :body, :text
    add_column :articles, :author, :string
    add_column :articles, :date_article, :timestamp
  end
end
