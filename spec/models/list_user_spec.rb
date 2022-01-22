# frozen_string_literal: true

# == Schema Information
#
# Table name: list_users
#
#  id         :bigint           not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :bigint
#  image      :string
#
require 'rails_helper'

RSpec.describe ListUser, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
