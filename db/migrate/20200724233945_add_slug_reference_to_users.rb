# frozen_string_literal: true

class AddSlugReferenceToUsers < ActiveRecord::Migration[6.0]
  def change
    add_reference :users, :slug, null: false, foreign_key: true
  end
end
