Rails.application.routes.draw do
  get 'errors/file_not_found'

  get 'errors/unprocessable'

  get 'errors/internal_server_error'

  get '/auth/:provider/callback', to: 'sessions#create'

  controller :users do
    get 'users/revisions' => 'users#revisions', :as => :user_revisions
  end

  controller :courses do
    get 'courses/*id/manual_update' => 'courses#manual_update', :as => :manual_update, constraints: { id: /.*/ }
    get 'courses/*id/students' => 'courses#students', :as => :students, constraints: { id: /.*/ }
    get 'courses/*id/articles' => 'courses#articles', :as => :path_save, constraints: { id: /.*/ }
    # Course titles on Wikipedia may include dots, so this constraint is needed.
    get 'courses/*id' => 'courses#students', constraints: { id: /.*/ }
    get 'courses' => 'courses#index'
  end

  resources :courses

  cohorts = Figaro.env.cohorts
  root to: 'courses#index', defaults: {
    cohort: cohorts.nil? ? 'spring_2015' : cohorts.split(',').last
  }

  match '/404', to: 'errors#file_not_found', via: :all
  match '/422', to: 'errors#unprocessable', via: :all
  match '/500', to: 'errors#internal_server_error', via: :all
end
