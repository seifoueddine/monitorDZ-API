# frozen_string_literal: true

class CreateListUsers < ActiveRecord::Migration[6.0]
  def change
    create_table :list_users do |t|
      t.string :name

      t.timestamps
    end
  end
end
