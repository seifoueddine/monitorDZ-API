# frozen_string_literal: true

class AddMoreColumnsToArtcile < ActiveRecord::Migration[6.0]
  def change
    add_reference :articles, :medium, null: false, foreign_key: true
    add_column :articles, :url_article, :string
  end
end
