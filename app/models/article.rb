# frozen_string_literal: true

class Article < ApplicationRecord
  searchkick match: :word,
             suggest: %i[title body media_area medium_type author_name tag_name],
             merge_mappings: true,
             mappings: {
               properties: {
                 body: {
                   type: 'text',
                   fields: {
                     analyzed: {
                       type: 'text',
                       analyzer: 'searchkick_index'
                     },
                     suggest: {
                       type: 'text',
                       analyzer: 'searchkick_suggest_index'
                     }
                   }
                 }
               }
             }
             settings: {
              index: {
                max_ngram_diff: 49,
                number_of_shards: 5,
                blocks: {
                  read_only_allow_delete: null
                },
                provided_name: articles_production_20211222190813288,
                max_shingle_diff: 4,
                creation_date: 1640196493297,
                analysis: {
                  filter: {
                    searchkick_suggest_shingle: {
                      max_shingle_size: 5,
                      type: shingle
                    },
                    searchkick_edge_ngram: {
                      type: edge_ngram,
                      min_gram: 1,
                      max_gram: 50
                    },
                    searchkick_index_shingle: {
                      token_separator: ,
                      type: shingle
                    },
                    searchkick_search_shingle: {
                      token_separator: ,
                      output_unigrams_if_no_shingles: true,
                      output_unigrams: false,
                      type: shingle
                    },
                    searchkick_stemmer: {
                      type: snowball,
                      language: English
                    },
                    searchkick_ngram: {
                      type: ngram,
                      min_gram: 1,
                      max_gram: 50
                    }
                  },
                  analyzer: {
                    searchkick_word_start_index: {
                      filter: [
                        lowercase,
                        asciifolding,
                        searchkick_edge_ngram
                      ],
                      type: custom,
                      tokenizer: standard
                    },
                    searchkick_keyword: {
                      filter: [
                        lowercase
                      ],
                      type: custom,
                      tokenizer: keyword
                    },
                    searchkick_text_end_index: {
                      filter: [
                        lowercase,
                        asciifolding,
                        reverse,
                        searchkick_edge_ngram,
                        reverse
                      ],
                      type: custom,
                      tokenizer: keyword
                    },
                    searchkick_search2: {
                      filter: [
                        lowercase,
                        asciifolding,
                        searchkick_stemmer
                      ],
                      char_filter: [
                        ampersand
                      ],
                      type: custom,
                      tokenizer: standard
                    },
                    searchkick_word_middle_index: {
                      filter: [
                        lowercase,
                        asciifolding,
                        searchkick_ngram
                      ],
                      type: custom,
                      tokenizer: standard
                    },
                    searchkick_search: {
                      filter: [
                        lowercase,
                        asciifolding,
                        searchkick_search_shingle,
                        searchkick_stemmer
                      ],
                      char_filter: [
                        ampersand
                      ],
                      type: custom,
                      tokenizer: standard
                    },
                    searchkick_text_start_index: {
                      filter: [
                        lowercase,
                        asciifolding,
                        searchkick_edge_ngram
                      ],
                      type: custom,
                      tokenizer: keyword
                    },
                    searchkick_word_end_index: {
                      filter: [
                        lowercase,
                        asciifolding,
                        reverse,
                        searchkick_edge_ngram,
                        reverse
                      ],
                      type: custom,
                      tokenizer: standard
                    },
                    searchkick_word_search: {
                      filter: [
                        lowercase,
                        asciifolding
                      ],
                      type: custom,
                      tokenizer: standard
                    },
                    searchkick_autocomplete_search: {
                      filter: [
                        lowercase,
                        asciifolding
                      ],
                      type: custom,
                      tokenizer: keyword
                    },
                    searchkick_suggest_index: {
                      filter: [
                        lowercase,
                        asciifolding,
                        searchkick_suggest_shingle
                      ],
                      type: custom,
                      tokenizer: standard
                    },
                    searchkick_text_middle_index: {
                      filter: [
                        lowercase,
                        asciifolding,
                        searchkick_ngram
                      ],
                      type: custom,
                      tokenizer: keyword
                    },
                    searchkick_index: {
                      filter: [
                        lowercase,
                        asciifolding,
                        searchkick_index_shingle,
                        searchkick_stemmer
                      ],
                      char_filter: [
                        ampersand
                      ],
                      type: custom,
                      tokenizer: standard
                    }
                  },
                  char_filter: {
                    ampersand: {
                      type: mapping,
                      mappings: [
                        &=> and 
                      ]
                    }
                  }
                },
                number_of_replicas: 1,
                uuid: ZHXyvQkjRFW3YQSX4jcE8Q,
                version: {
                  created: 6081399
                }
              }
            }
  #   after_commit :reindex_data
  #
  #   def reindex_data
  #     author.reindex
  #     tags.reindex
  #     medium.reindex
  #   end

  # after_commit :indexing
  # acts_as_authorable
  scope :search_import, -> { includes(:author, :medium, :tags) }
  has_many :article_tags
  has_many :tags, through: :article_tags
  belongs_to :author
  belongs_to :medium
  has_many :list_articles
  has_many :list_users, through: :list_articles
  mount_uploader :image, ImageUploader

  def search_data
    {
      title: title,
      body: body,
      author_name: author.name,
      tag_name: tags.map(&:name),
      medium_type: medium.media_type,
      media_area: medium.zone,
      medium_id: medium_id,
      date_published: date_published,
      is_tagged: is_tagged,
      author_id: author_id,
      language: language
    }
  end

  # protected

  # def indexing
  # Article.reindex
  #  Medium.reindex
  # end
end
