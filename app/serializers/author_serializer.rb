# frozen_string_literal: true

# == Schema Information
#
# Table name: authors
#
#  id             :bigint           not null, primary key
#  name           :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  medium_id      :integer
#  articles_count :integer
#
class AuthorSerializer
  include JSONAPI::Serializer
  attributes :name, :medium_id, :articles_count
end
