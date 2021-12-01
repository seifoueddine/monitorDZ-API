# frozen_string_literal: true

class CategoryToArticles < ActiveRecord::Migration[6.0]
  def change
    add_column :articles, :category_article, :string
  end
end
