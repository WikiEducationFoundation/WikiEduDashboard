Rails.application.routes.draw do

  resources :courses

  root to: 'courses#index'
  
end
