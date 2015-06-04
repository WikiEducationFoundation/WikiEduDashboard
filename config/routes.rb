# Page titles on Wikipedia may include dots, so this constraint is needed.

Rails.application.routes.draw do
  get 'errors/file_not_found'

  get 'errors/unprocessable'

  get 'errors/internal_server_error'

  # Sessions
  devise_for :users, controllers: { omniauth_callbacks: 'omniauth_callbacks' }
  devise_scope :user do
    get 'sign_in', to: 'devise/sessions#new', as: :new_user_session
    get 'sign_out', to: 'users#signout', as: :destroy_user_session
    get 'sign_out_oauth', to: 'devise/sessions#destroy',
                          as: :true_destroy_user_session
  end

  # Users
  controller :users do
    get 'users/revisions' => 'users#revisions', :as => :user_revisions
  end

  # Courses
  controller :courses do
    get 'courses/new' => 'courses#new',
        constraints: { id: /.*/ } # repeat of resources

    get 'courses/*id/manual_update' => 'courses#manual_update',
        :as => :manual_update, constraints: { id: /.*/ }
    get 'courses/*id/notify_untrained' => 'courses#notify_untrained',
        :as => :notify_untrained, constraints: { id: /.*/ }

    get 'courses/*id/overview' => 'courses#overview',
        :as => :overview, constraints: { id: /.*/ }
    get 'courses/*id/timeline(/*any)' => 'courses#timeline',
        :as => :timeline, constraints: { id: /.*/ }
    get 'courses/*id/activity' => 'courses#activity',
        :as => :activity, constraints: { id: /.*/ }
    get 'courses/*id/students' => 'courses#students',
        :as => :students, constraints: { id: /.*/ }
    get 'courses/*id/articles' => 'courses#articles',
        :as => :articles, constraints: { id: /.*/ }
    get 'courses/*id/uploads' => 'courses#uploads',
        :as => :uploads, constraints: { id: /.*/ }
  end

  # Enrollment
  post 'courses/:course_id/students/enroll' => 'users#enroll',
       constraints: { course_id: /.*/ }
  post 'courses/:course_id/students/:user_id/unenroll' => 'users#unenroll',
       constraints: { course_id: /.*/ }
  post 'courses/:course_id/students/:user_id/setrole' => 'users#setrole',
       constraints: { course_id: /.*/ }

  # Assignments
  post 'courses/:course_id/students/assign' => 'users#assign',
       constraints: { course_id: /.*/ }
  post 'courses/:course_id/students/unassign' => 'users#unassign',
       constraints: { course_id: /.*/ }

  # Assignment reviewers
  post 'courses/:course_id/students/review' => 'users#review',
       constraints: { course_id: /.*/ }
  post 'courses/:course_id/students/unreview' => 'users#unreview',
       constraints: { course_id: /.*/ }

  # Timeline
  resources :courses, constraints: { id: /(.*?\))/ } do
    resources :weeks, only: [:index, :new, :create], constraints: { id: /.*/ }
    # get 'courses' => 'courses#index'
  end
  resources :weeks, only: [:show, :edit, :update, :destroy]
  resources :blocks, only: [:show, :edit, :update, :destroy]
  resources :gradeables, collection: { update_multiple: :put }
  post 'courses/:course_id/timeline' => 'timeline#update_timeline',
       constraints: { course_id: /.*/ }
  post 'courses/:course_id/gradeables' => 'timeline#update_gradeables',
       constraints: { course_id: /.*/ }

  # Wizard
  get 'wizards' => 'wizard#wizard_index'
  get 'wizards/:wizard_id' => 'wizard#wizard'
  post 'courses/:course_id/wizard/:wizard_id' => 'wizard#submit_wizard',
       constraints: { course_id: /.*/ }

  # Misc
  get 'courses' => 'courses#index'
  get 'talk' => 'courses#talk'
  get 'courses/*id' => 'courses#show', :as => :show, constraints: { id: /.*/ }

  # Root
  root to: 'courses#index'

  # Route aliases for React frontend
  get '/course_creator(/*any)' => 'courses#index'

  # Errors
  match '/404', to: 'errors#file_not_found', via: :all
  match '/422', to: 'errors#unprocessable', via: :all
  match '/500', to: 'errors#internal_server_error', via: :all
end
