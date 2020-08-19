class Article < ApplicationRecord
    belongs_to :medium
    has_many :article_tags
    has_many :tags, through: :article_tags
end
