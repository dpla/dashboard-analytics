Rails.application.routes.draw do
  devise_for :users

  namespace :admin do
    resources :users
  end

  resources :hubs, only: [:index, :show] do
    resources :contributors, only: :show  
  end

  root 'hubs#index'
end
