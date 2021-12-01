# frozen_string_literal: true

class ChangeNameColumnInMediaSectors < ActiveRecord::Migration[6.0]
  def change
    rename_column :media_sectors, :media_id, :medium_id
  end
end
