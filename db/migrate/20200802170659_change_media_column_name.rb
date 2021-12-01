# frozen_string_literal: true

class ChangeMediaColumnName < ActiveRecord::Migration[6.0]
  def change
    rename_column :media, :type, :media_type
  end
end
