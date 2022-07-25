require 'rails_helper'
RSpec.describe '/users', type: :request do
    # This should return the minimal set of attributes required to create a valid
    # User. As you add validations to User, be sure to
    # adjust the attributes here as well.
  
    before(:all) do
      @slug = FactoryBot.create(:slug)
      @user_sign_in = FactoryBot.create(:user)
      sign_in @user_sign_in
    end
  
    let(:auth_headers) { @user_sign_in.create_new_auth_token }
    let(:valid_attributes) do
      {
        email: 'Salim@salim.salim',
        password: '123456789',
        name: 'Salim',
        slug_id: @slug.id
      }
    end
  
    let(:invalid_attributes) do
      {
        email: 'Salimalim.salim',
        password: '123456789',
        name: 12345,
        slug_id: @slug.id
      }
    end
  
    # This should return the minimal set of values that should be in the headers
    # in order to pass any filters (e.g. authentication) defined in
    # UsersController, or in your router and rack
    # middleware. Be sure to keep this updated too.
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
        FactoryBot.create(:user)
        get '/api/v1/users', headers: valid_headers, as: :json
        expect(response).to be_successful
      end
  
      it 'renders a unauthorized status' do
        FactoryBot.create(:user) 
        get '/api/v1/users', headers: invalid_headers, as: :json
        expect(response).to have_http_status(:unauthorized)
      end
  
      it 'renders a successful response with search ' do
        User.create! valid_attributes
        get '/api/v1/users?search=Salim',  headers: valid_headers, as: :json
        result =  JSON.parse(response.body)
        expect(result['data'].count).to eq(1)
      end
  
    end
  
    describe 'GET User by ID' do
      it 'renders a successful response' do
        user = FactoryBot.create(:user) 
        get "/api/v1/users/#{user.id}", headers: valid_headers, as: :json
        expect(response).to be_successful
      end
    end
  
    describe 'POST /create' do
      context 'with valid parameters' do
        it 'creates a new User' do
          expect do
            post '/api/v1/users',
                 params: { user: valid_attributes }, headers: valid_headers, as: :json
          end.to change(User, :count).by(1)
        end
  
        it 'renders a JSON response with the new user' do
          post '/api/v1/users',
               params: { user: valid_attributes }, headers: valid_headers, as: :json
          expect(response).to have_http_status(:created)
          expect(response.content_type).to match(a_string_including('application/json'))
        end
      end
  
      context 'with invalid parameters' do
        it 'does not create a new User' do
          expect do
            post '/api/v1/users',
                 params: { user: invalid_attributes }, as: :json
          end.to change(User, :count).by(0)
        end
  
        it 'renders a JSON response with errors for the new user' do
          post '/api/v1/users',
               params: { user: invalid_attributes }, headers: valid_headers, as: :json
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.content_type).to eq('application/json; charset=utf-8')
        end
      end
    end
  
    describe 'PATCH /update' do
      context 'with valid parameters' do
        let(:new_attributes) do
          {
            name: 'New user name'
          }
        end

        let(:new_password_attributes) do
            {
              password: '987654321'
            }
          end
  
        it 'updates the requested user' do
          user = FactoryBot.create(:user) 
          patch "/api/v1/users/#{user.id}",
                params: { user: new_attributes }, headers: valid_headers, as: :json
          user.reload
          expect(user.attributes).to include( { "name" => 'New user name' } )
        end
  
        it 'renders a JSON response with the user' do
          user = FactoryBot.create(:user) 
          put "/api/v1/users/#{user.id}",
              params: { user: new_attributes }, headers: valid_headers, as: :json
          expect(response).to have_http_status(:ok)
          expect(response.content_type).to match(a_string_including('application/json'))
        end


        it 'renders a JSON response with the user' do
            user = FactoryBot.create(:user) 
            put "/api/v1/users/change_password/#{user.id}",
                params: { user: new_password_attributes }, headers: valid_headers, as: :json
            expect(response).to have_http_status(:ok)
            expect(response.content_type).to match(a_string_including('application/json'))
          end


      end
  
      context 'with invalid parameters' do
        it 'renders a JSON response with errors for the user' do
          user = FactoryBot.create(:user) 
          patch "/api/v1/users/#{user.id}",
                params: { user: invalid_attributes }, headers: valid_headers, as: :json
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.content_type).to eq('application/json; charset=utf-8')
        end
      end
    end
  
    describe 'DELETE /destroy' do
      it 'destroys the requested user' do
        user = FactoryBot.create(:user) 
        expect do
          delete "/api/v1/users/#{user.id}", headers: valid_headers, as: :json
        end.to change(User, :count).by(-1)
      end
    end
  end