Rails.application.routes.draw do
  get 'errors/file_not_found'

  get 'errors/unprocessable'

  get 'errors/internal_server_error'

  controller :users do
    get 'users/revisions' => 'users#revisions', :as => :user_revisions
  end

  controller :courses do
    get 'courses/*id/students' => 'courses#students', :as => :students, constraint: { id: /.*/ }
    get 'courses/*id/articles' => 'courses#articles', :as => :path_save, constraint: { id: /.*/ }
    # Course titles on Wikipedia may include dots, so this constraint is needed.
    get 'courses/*id' => 'courses#students', constraint: { id: /.*/ }
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
