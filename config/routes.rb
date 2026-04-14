Rails.application.routes.draw do
  get "/health", to: proc { [200, {}, ["ok"]] }

  devise_for :users, skip: [:registrations, :passwords]
  as :user do
    get 'users/edit', to: 'devise/registrations#edit', as: :edit_user_registration
    put 'users', to: 'devise/registrations#update', as: :user_registration
    # Password routes are defined explicitly here because devise_for does not
    # generate them automatically in this app's configuration.
    get  'users/password/new',  to: 'devise/passwords#new',    as: :new_user_password
    get  'users/password/edit', to: 'devise/passwords#edit',   as: :edit_user_password
    post 'users/password',      to: 'devise/passwords#create', as: :user_password
    put  'users/password',      to: 'devise/passwords#update'
    patch 'users/password',     to: 'devise/passwords#update'
  end

  namespace :admin do
    resources :users do
      member do
        post :send_password_reset
      end
    end
    post "wikimedia_cache/rebuild", to: "wikimedia_cache#rebuild"
  end

  resources :hubs, id: /.*/, only: [:index, :show] do
    get :sections
    get :website_overview
    get :api_overview
    get :bws_overview
    get :item_count
    get :totals
    get :metadata_completeness
    get :wikimedia_overview

    resources :contributors, id: /.*/, only: [:index, :show] do
      get :sections
      get :contributor_website_overview
      get :contributor_api_overview
      get :contributor_bws_overview
      get :contributor_item_count
      get :contributor_totals
      get :contributor_metadata_completeness
      get :contributor_wikimedia_overview
      resources :events, only: [:show]
      resources :locations, only: [:index]
      resources :timelines, only: [:show]
      resources :wikimedia_preparations, only: [:index]
    end
    resources :events, only: [:show]
    resources :locations, only: [:index]
    resources :timelines, only: [:show]
    resources :wikimedia_preparations, only: [:index]
  end

  resources :search_terms, only: [:show]

  get :api_events, controller: :events
  get :website_events, controller: :events
  get :bws_events, controller: :events
  get :api_search_terms, controller: :search_terms
  get :website_search_terms, controller: :search_terms
  get :contributor_comparison, controller: :contributors
  get :contributor_ga_data,   controller: :contributors

  root 'hubs#index'
end
