# frozen_string_literal: true

class AddSlugToArticleTag < ActiveRecord::Migration[6.1]
  def change
    add_column :article_tags, :slug_id, :integer
  end
end
