Rails.application.routes.draw do

  get 'errors/file_not_found'

  get 'errors/unprocessable'

  get 'errors/internal_server_error'

  controller :users do
    get 'users/revisions' => "users#revisions", :as => :user_revisions
  end

  controller :courses do
    get "courses/*id/students" => "courses#students", :as => :students
    get "courses/*id/articles" => "courses#articles", :as => :path_save
    get "courses/*id" => "courses#students", :constraints => { :id => /.*/ } 
  end

  resources :courses

  root to: 'courses#index', :defaults => { :cohort => Figaro.env.cohorts.nil? ? "spring_2015" : Figaro.env.cohorts.split(",").last }

  match '/404', to: 'errors#file_not_found', via: :all
  match '/422', to: 'errors#unprocessable', via: :all
  match '/500', to: 'errors#internal_server_error', via: :all

end


