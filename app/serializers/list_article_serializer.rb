# frozen_string_literal: true

# == Schema Information
#
# Table name: list_articles
#
#  id           :bigint           not null, primary key
#  article_id   :integer
#  list_user_id :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
class ListArticleSerializer
  include JSONAPI::Serializer
  attributes
end
