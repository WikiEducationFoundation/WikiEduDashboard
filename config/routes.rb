Rails.application.routes.draw do

  resources :courses
  controller :courses do
    get "courses/:id/show" => "courses#show", :as => :show
    get "courses/:id/students" => "courses#students", :as => :students
    get "courses/:id/articles" => "courses#articles", :as => :path_save
  end

  root to: 'courses#index'

end
