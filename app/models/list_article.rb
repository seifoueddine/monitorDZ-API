class ListArticle < ApplicationRecord
  belongs_to :article
  belongs_to :list_user
end
