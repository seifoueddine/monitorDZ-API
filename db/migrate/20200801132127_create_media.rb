# frozen_string_literal: true

class CreateMedia < ActiveRecord::Migration[6.0]
  def change
    create_table :media do |t|
      t.string :name
      t.string :type
      t.string :orientation

      t.timestamps
    end
  end
end
