Rails.application.routes.draw do
  devise_for :users, skip: [:registrations]
  as :user do
    get 'users/edit' => 'devise/registrations#edit', as: 'edit_user_registration'
    put 'users' => 'devise/registrations#update', as: 'user_registration'
  end

  namespace :admin do
    resources :users
  end

  resources :hubs, id: /.*/, only: [:index, :show] do
    get :website_overview
    get :api_overview
    get :item_count
    get :metadata_completeness

    resources :contributors, id: /.*/, only: [:index, :show] do
      get :contributor_website_overview
      get :contributor_api_overview
      get :contributor_item_count
      get :contributor_metadata_completeness
      resources :events, only: [:show]
      resources :locations, only: [:index]
      resources :timelines, only: [:show]
    end
    resources :events, only: [:show]
    resources :locations, only: [:index]
    resources :timelines, only: [:show]
    resources :wikimedia_readiness, only: [:show]
  end

  resources :search_terms, only: [:show]

  get :api_events, controller: :events
  get :website_events, controller: :events
  get :api_search_terms, controller: :search_terms
  get :website_search_terms, controller: :search_terms
  get :contributor_comparison, controller: :contributors

  root 'hubs#index'
end
