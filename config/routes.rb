Rails.application.routes.draw do
  mount RailsIcons::Engine, at: '/rails_icons'
  resources :posts
  root 'posts#index'

  get 'up' => 'rails/health#show', as: :rails_health_check
end
