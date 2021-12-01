# frozen_string_literal: true

task indexing: :environment do
  Article.reindex
end
