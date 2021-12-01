# frozen_string_literal: true

class AddAuthorRefToArticle < ActiveRecord::Migration[6.0]
  def change
    add_reference :articles, :author, foreign_key: true
  end
end
