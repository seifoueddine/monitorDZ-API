FactoryBot.define do
    factory :slug do
      name { Faker::Lorem.word }
    end
  end