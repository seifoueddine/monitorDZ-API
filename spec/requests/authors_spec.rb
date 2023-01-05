# frozen_string_literal: true

require 'rails_helper'

RSpec.describe '/authors', type: :request do
  before(:all) do
    @user = FactoryBot.create(:user)
    sign_in @user
  end
  let(:auth_headers) { @user.create_new_auth_token }
  let(:valid_attributes) do
    {
      name: 'Mohamed Salim'
    }
  end

  let(:invalid_attributes) do
    {
      name: 321
    }
  end

  let(:valid_headers) do
    {
      'Uid' => auth_headers['uid'],
      'Access-Token' => auth_headers['access-token'],
      'Client' => auth_headers['client'],
      'slug-id' => @user.slug_id
    }
  end
  let(:invalid_headers) do
    {
      'Uid' => auth_headers['uid']
    }
  end

  describe 'GET /index' do
    it 'renders a successful response' do
      Author.create! valid_attributes
      get '/api/v1/authors', headers: valid_headers, as: :json
      expect(response).to be_successful
    end

    it 'renders a unauthorized status' do
      Author.create! valid_attributes
      get '/api/v1/authors', headers: invalid_headers, as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it 'renders a successful response with search ' do
      Author.create! valid_attributes
      get '/api/v1/authors?search=Salim', headers: valid_headers, as: :json
      result = JSON.parse(response.body)
      expect(result['data'].count).to eq(1)
    end

    let(:author_valid_attributes) do
      {
        name: 'Mohamed Salim',
        medium_id: 25
      }
    end

    it 'renders a successful response with filter medium ' do
      Author.create! author_valid_attributes
      get '/api/v1/authors?medium_id=25', headers: valid_headers, as: :json
      result = JSON.parse(response.body)
      expect(result['data'].count).to eq(1)
    end
  end

  describe 'GET /show' do
    it 'renders a successful response' do
      author = Author.create! valid_attributes
      get "/api/v1/authors/#{author.id}", headers: valid_headers, as: :json
      expect(response).to be_successful
    end
  end

  describe 'POST /create' do
    context 'with valid parameters' do
      it 'creates a new Author' do
        expect do
          post '/api/v1/authors',
               params: { author: valid_attributes }, headers: valid_headers, as: :json
        end.to change(Author, :count).by(1)
      end

      it 'renders a JSON response with the new author' do
        post '/api/v1/authors',
             params: { author: valid_attributes }, headers: valid_headers, as: :json
        expect(response).to have_http_status(:created)
        expect(response.content_type).to match(a_string_including('application/json'))
      end
    end

    context 'with invalid parameters' do
      it 'does not create a new Author' do
        expect do
          post '/api/v1/authors',
               params: { author: invalid_attributes }, as: :json
        end.to change(Author, :count).by(0)
      end

      it 'renders a JSON response with errors for the new author' do
        post '/api/v1/authors',
             params: { author: invalid_attributes }, headers: valid_headers, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json; charset=utf-8')
      end
    end
  end

  describe 'PATCH /update' do
    context 'with valid parameters' do
      let(:new_attributes) do
        {
          name: 'Omar'
        }
      end

      it 'updates the requested author' do
        author = Author.create! valid_attributes
        patch "/api/v1/authors/#{author.id}",
              params: { author: new_attributes }, headers: valid_headers, as: :json
        author.reload
        expect(author.attributes).to include({ 'name' => 'Omar' })
      end

      it 'renders a JSON response with the author' do
        author = Author.create! valid_attributes
        patch "/api/v1/authors/#{author.id}",
              params: { author: new_attributes }, headers: valid_headers, as: :json
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to match(a_string_including('application/json'))
      end
    end

    context 'with invalid parameters' do
      it 'renders a JSON response with errors for the author' do
        author = Author.create! valid_attributes
        patch "/api/v1/authors/#{author.id}",
              params: { author: invalid_attributes }, headers: valid_headers, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json; charset=utf-8')
      end
    end
  end

  describe 'DELETE /destroy' do
    context 'Delete if campaign had medium' do
      let(:medium_valid_attributes) do
        {
          name: 'Elkhabar',
          url_crawling: 'www.elkhabar.com'
        }
      end

      let(:article_valid_attributes) do
        {
          title: 'Campaign Name',
          medium_id: @medium.id,
          author_id: @author.id
        }
      end
      it 'destroys the requested medium' do
        @medium = Medium.create! medium_valid_attributes
        @author = Author.create! valid_attributes
        article = Article.create! article_valid_attributes
        expect do
          delete "/api/v1/authors/#{@author.id}", headers: valid_headers, as: :json
        end.to change(Author, :count).by(0)
      end
    end

    it 'destroys the requested author' do
      author = Author.create! valid_attributes
      expect do
        delete "/api/v1/authors/#{author.id}", headers: valid_headers, as: :json
      end.to change(Author, :count).by(-1)
    end
  end

  describe 'GET authors_client' do
    context 'get authors for each client' do
      let(:medium_valid_attributes) do
        {
          name: 'Elkhabar',
          url_crawling: 'www.elkhabar.com'
        }
      end

      let(:article_valid_attributes) do
        {
          title: 'Campaign Name',
          medium_id: @medium.id,
          author_id: @author.id
        }
      end
      let(:slug_valid_attributes) do
        {
          name: 'Corporate name'
        }
      end

      let(:campaign_valid_attributes) do
        {
          name: 'Campaign Name',
          slug_id: @user.slug_id
        }
      end
      it 'render authros list' do
        # @slug = Slug.create! slug_valid_attributes
        campaign = Campaign.create! campaign_valid_attributes
        @medium = Medium.create! medium_valid_attributes
        campaign.media = Medium.where(id: @medium.id)

        @author = Author.create! valid_attributes
        article = Article.create! article_valid_attributes

        get '/api/v1/authors_client', headers: valid_headers, as: :json
        expect(response).to be_successful
      end
    end
  end
end
