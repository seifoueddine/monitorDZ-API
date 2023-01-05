# frozen_string_literal: true

require 'rails_helper'
RSpec.describe '/media', type: :request do
  before(:all) do
    @user = FactoryBot.create(:user)
    sign_in @user
  end
  let(:auth_headers) { @user.create_new_auth_token }
  let(:valid_attributes) do
    {
      name: 'elkhabar',
      url_crawling: 'https://www.elkhabar.com/press/category/36/%D8%A7%D9%84%D8%B9%D8%A7%D9%84%D9%85/',
      language: 'fr'
    }
  end

  let(:invalid_attributes) do
    {
      name: 321,
      url_crawling: 1558
    }
  end

  let(:valid_headers) do
    {
      'Uid' => auth_headers['uid'],
      'Access-Token' => auth_headers['access-token'],
      'Client' => auth_headers['client']
    }
  end
  let(:invalid_headers) do
    {
      'Uid' => auth_headers['uid']
    }
  end

  describe 'GET /index' do
    it 'renders a successful response' do
      Medium.create! valid_attributes
      get '/api/v1/media', headers: valid_headers, as: :json
      expect(response).to be_successful
    end

    it 'renders a unauthorized status' do
      Medium.create! valid_attributes
      get '/api/v1/media', headers: invalid_headers, as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it 'renders a successful response with search ' do
      Medium.create! valid_attributes
      get '/api/v1/media?search=elkhabar', headers: valid_headers, as: :json
      result = JSON.parse(response.body)
      expect(result['data'].count).to eq(1)
    end
  end

  describe 'GET /show' do
    it 'renders a successful response' do
      medium = Medium.create! valid_attributes
      get "/api/v1/media/#{medium.id}", headers: valid_headers, as: :json
      expect(response).to be_successful
    end
  end

  describe 'POST /create' do
    context 'with valid parameters' do
      it 'creates a new Medium' do
        expect do
          post '/api/v1/media',
               params: valid_attributes, headers: valid_headers, as: :json
        end.to change(Medium, :count).by(1)
      end

      it 'renders a JSON response with the new medium' do
        post '/api/v1/media',
             params:  valid_attributes, headers: valid_headers, as: :json
        expect(response).to have_http_status(:created)
        expect(response.content_type).to match(a_string_including('application/json'))
      end
    end

    context 'with invalid parameters' do
      it 'does not create a new Medium' do
        expect do
          post '/api/v1/media',
               params: invalid_attributes, as: :json
        end.to change(Medium, :count).by(0)
      end

      it 'renders a JSON response with errors for the new medium' do
        post '/api/v1/media',
             params:  invalid_attributes, headers: valid_headers, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json; charset=utf-8')
      end
    end
  end

  describe 'PATCH /update' do
    context 'with valid parameters' do
      let(:new_attributes) do
        {
          name: 'cherouk',
          url_crawling: 'https://www.cherouk.com/press/category',
          language: 'fr'
        }
      end

      it 'updates the requested medium' do
        medium = Medium.create! valid_attributes
        patch "/api/v1/media/#{medium.id}",
              params: { medium: new_attributes }, headers: valid_headers, as: :json
        medium.reload
        expect(medium.attributes).to include({ 'name' => 'cherouk' })
      end

      it 'renders a JSON response with the medium' do
        medium = Medium.create! valid_attributes
        patch "/api/v1/media/#{medium.id}",
              params: { medium: new_attributes }, headers: valid_headers, as: :json
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to match(a_string_including('application/json'))
      end
    end

    context 'with invalid parameters' do
      it 'renders a JSON response with errors for the medium' do
        medium = Medium.create! valid_attributes
        patch "/api/v1/media/#{medium.id}",
              params: { medium: invalid_attributes }, headers: valid_headers, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json; charset=utf-8')
      end
    end
  end

  describe 'DELETE /destroy' do
    context 'Delete if campaign had medium' do
      let(:slug_valid_attributes) do
        {
          name: 'Corporate name'
        }
      end

      let(:campaign_valid_attributes) do
        {
          name: 'Campaign Name',
          slug_id: @slug.id
        }
      end
      it 'destroys the requested medium' do
        @slug = Slug.create! slug_valid_attributes
        campaign = Campaign.create! campaign_valid_attributes
        medium = Medium.create! valid_attributes
        campaign.media = Medium.where(id: medium.id)

        expect do
          delete "/api/v1/media/#{medium.id}", headers: valid_headers, as: :json
        end.to change(Medium, :count).by(0)
      end
    end

    context 'Delete campaignm' do
      it 'destroys the requested medium' do
        medium = Medium.create! valid_attributes

        expect do
          delete "/api/v1/media/#{medium.id}", headers: valid_headers, as: :json
        end.to change(Medium, :count).by(-1)
      end
    end
  end
end
