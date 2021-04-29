Rails.application.routes.draw do




  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  devise_for :users
  namespace :api do
    scope :v1 do
      mount_devise_token_auth_for 'User', at: 'auth'
    end
  end

  namespace :api do
    namespace :v1 do
      put 'users/change_password/:id', to: 'users#change_password'
      resources :users
      resources :authors
      resources :slugs
      resources :sectors
      resources :campaigns
      resources :media
      resources :articles
      resources :tags
      resources :list_users
      post 'articles/change_status', to: 'articles#change_status'
      get 'articles_for_sorting', to: 'articles#articles_for_sorting'
      get 'get_articles/crawling', to: 'articles#crawling'
      get 'auto_tags', to: 'articles#auto_tag'
      get 'search_article', to: 'articles#search_article'
      get 'articles_client', to: 'articles#articles_client'
      get 'authors_client', to: 'authors#authors_client'
      get 'pdf_export', to: 'articles#pdf_export'
      post 'send_email', to: 'articles#send_email'
      get 'articles_by_medium', to: 'articles#articles_by_medium'
      get 'articles_by_author', to: 'articles#articles_by_author'
      get 'articles_by_tag', to: 'articles#articles_by_tag'
    end
  end



end
