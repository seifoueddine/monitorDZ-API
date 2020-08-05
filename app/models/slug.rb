class Slug < ApplicationRecord
    validates_uniqueness_of :name
    has_many :users, dependent: :destroy
    has_many :campaigns, dependent: :destroy
end
