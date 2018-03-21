Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  resources :hubs, only: [:index, :show]
  root 'hubs#index'
end
