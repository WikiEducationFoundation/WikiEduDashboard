Rails.application.routes.draw do

  controller :courses do
    get "courses/:id" => "courses#show"
    get "courses/:id/students" => "courses#students", :as => :students
    get "courses/:id/articles" => "courses#articles", :as => :path_save
  end
  resources :courses

  root to: 'courses#index'

end
