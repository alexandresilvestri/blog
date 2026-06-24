Rails.application.routes.draw do
  mount RailsIcons::Engine, at: '/rails_icons'
  resources :posts
  resource :session, only: %i[create destroy]
  get 'admin', to: 'sessions#new', as: :admin
  get 'session/verify/:token', to: 'sessions#verify', as: :verify_session
  root 'posts#index'

  get 'up' => 'rails/health#show', as: :rails_health_check
end
