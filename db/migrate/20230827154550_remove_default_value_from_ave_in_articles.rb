class RemoveDefaultValueFromAveInArticles < ActiveRecord::Migration[6.1]
  def change
    change_column_default :articles, :ave, from: "NEUTRAL", to: nil
  end
end
