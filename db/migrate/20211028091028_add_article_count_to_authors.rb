# frozen_string_literal: true

class AddArticleCountToAuthors < ActiveRecord::Migration[6.1]
  def change
    add_column :authors, :articles_count, :integer
  end
end
