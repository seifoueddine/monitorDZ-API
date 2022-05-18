# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Articles', type: :request do
  describe 'GET /articles' do
    it 'works! (now write some real specs)' do
      get 'http://127.0.0.1:3000/api/v1/articles'
      expect(response).to have_http_status(200)
    end
  end
end
