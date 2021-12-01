# frozen_string_literal: true

class AddTagStatusToMedia < ActiveRecord::Migration[6.0]
  def change
    add_column :media, :tag_status, :boolean
  end
end
