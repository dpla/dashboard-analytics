Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  resources :hubs, only: [:index, :show] do
    resources :contributors, only: :show  
  end

  root 'hubs#index'
end
