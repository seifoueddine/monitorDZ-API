# frozen_string_literal: true

class ChangeColumnsInArticles < ActiveRecord::Migration[6.0]
  def change
    change_column :articles, :date_published, :string
  end
end
