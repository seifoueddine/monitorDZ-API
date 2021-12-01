# frozen_string_literal: true

class AddMoreColumnsToArticlesAndMedias < ActiveRecord::Migration[6.0]
  def change
    add_column :media, :avatar, :string
    add_column :articles, :status, :string
  end
end
