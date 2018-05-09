Rails.application.routes.draw do
  devise_for :users, skip: [:registrations]
  as :user do
    get 'users/edit' => 'devise/registrations#edit', as: 'edit_user_registration'
    put 'users' => 'devise/registrations#update', as: 'user_registration'
  end

  namespace :admin do
    resources :users
  end

  resources :hubs, only: [:index, :show] do
    resources :contributors, only: [:index, :show] do
      resources :events, only: [:show]
      resources :locations, only: [:show]
    end
    resources :events, only: [:show]
    resources :locations, only: [:index]
  end

  root 'hubs#index'
end
