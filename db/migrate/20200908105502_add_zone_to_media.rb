# frozen_string_literal: true

class AddZoneToMedia < ActiveRecord::Migration[6.0]
  def change
    add_column :media, :zone, :string
    add_column :media, :language, :string
  end
end
