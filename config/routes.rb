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
      resources :authors
      resources :slugs
      resources :sectors
      resources :campaigns
      resources :media
      resources :articles
      resources :tags
      get 'get_articles/crawling', to: 'articles#crawling'
      get 'auto_tags', to: 'articles#auto_tag'
      get 'search_article', to: 'articles#search_article'
    end
  end



end
