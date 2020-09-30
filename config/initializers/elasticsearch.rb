# frozen_string_literal: true

if Rails.env == 'production'
  url = ENV['BONSAI_URL']
  transport_options = { request: { timeout: 250 } }
  options = { hosts: url, retry_on_failure: true, transport_options: transport_options }
  Searchkick.client = Elasticsearch::Client.new(options)
  ENV['ELASTICSEARCH_URL'] = 'http://localhost:9200'
end