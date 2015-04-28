# Page titles on Wikipedia may include dots, so this constraint is needed.

Rails.application.routes.draw do
  get 'errors/file_not_found'

  get 'errors/unprocessable'

  get 'errors/internal_server_error'

  devise_for :users, controllers: { omniauth_callbacks: 'omniauth_callbacks' }
  devise_scope :user do
    get 'sign_in', to: 'devise/sessions#new', as: :new_user_session
    get 'sign_out', to: 'users#signout', as: :destroy_user_session
    get 'sign_out_oauth', to: 'devise/sessions#destroy',
                          as: :true_destroy_user_session
  end

  controller :users do
    get 'users/revisions' => 'users#revisions', :as => :user_revisions
  end

  controller :courses do
    get 'courses/new' => 'courses#new' # repeat of resources

    get 'courses/*id/manual_update' => 'courses#manual_update',
        :as => :manual_update, constraints: { id: /.*/ }
    get 'courses/*id/notify_untrained' => 'courses#notify_untrained',
        :as => :notify_untrained, constraints: { id: /.*/ }

    get 'courses/*id/students' => 'courses#students',
        :as => :students, constraints: { id: /.*/ }
    get 'courses/*id/articles' => 'courses#articles',
        :as => :path_save, constraints: { id: /.*/ }
    get 'courses/*id/timeline' => 'courses#timeline',
        :as => :timeline, constraints: { id: /.*/ }
  end

  resources :courses, constraints: { id: /.*/ } do
    resources :weeks, only: [:index, :new, :create], constraints: { id: /.*/ } do
      resources :blocks, only: [:index, :new, :create], constraints: { id: /.*/ }
    end
  end
  resources :weeks, only: [:show, :edit, :update, :destroy]
  resources :blocks, only: [:show, :edit, :update, :destroy]

  post 'courses/:course_id/weeks/mass_update' => 'weeks#mass_update',
       constraints: { course_id: /.*/ }

  get 'courses/*id' => 'courses#students', constraints: { id: /.*/ }
  get 'courses' => 'courses#index'
  get 'talk' => 'courses#talk'

  cohorts = Cohort.all.order(:created_at)
  db_init = ActiveRecord::Base.connection.table_exists? 'cohorts'
  root to: 'courses#index', defaults: {
    cohort: !db_init || cohorts.empty? ? 'spring_2015' : cohorts.last.slug
  }

  match '/404', to: 'errors#file_not_found', via: :all
  match '/422', to: 'errors#unprocessable', via: :all
  match '/500', to: 'errors#internal_server_error', via: :all
end
