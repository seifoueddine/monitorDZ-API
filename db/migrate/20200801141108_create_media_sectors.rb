# frozen_string_literal: true

class CreateMediaSectors < ActiveRecord::Migration[6.0]
  def change
    create_table :media_sectors do |t|
      t.integer :media_id
      t.integer :sector_id

      t.timestamps
    end
  end
end
