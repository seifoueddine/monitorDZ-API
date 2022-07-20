# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    association :slug   
    email { Faker::Internet.email }
    password { Faker::Internet.password }
    name { Faker::Lorem.word }
    
  end
end
