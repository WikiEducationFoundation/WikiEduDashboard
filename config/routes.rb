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
    get 'courses/new' => 'courses#new',
        onstraints: { id: /.*/ } # repeat of resources

    get 'courses/*id/manual_update' => 'courses#manual_update',
        :as => :manual_update, constraints: { id: /.*/ }
    get 'courses/*id/notify_untrained' => 'courses#notify_untrained',
        :as => :notify_untrained, constraints: { id: /.*/ }

    get 'courses/*id/activity' => 'courses#activity',
        :as => :activity, constraints: { id: /.*/ }
    get 'courses/*id/students' => 'courses#students',
        :as => :students, constraints: { id: /.*/ }
    get 'courses/*id/articles' => 'courses#articles',
        :as => :path_save, constraints: { id: /.*/ }
    get 'courses/*id/timeline(/*any)' => 'courses#timeline',
        :as => :timeline, constraints: { id: /.*/ }
    get 'courses/*id/overview' => 'courses#overview',
        :as => :overview, constraints: { id: /.*/ }
  end

  resources :courses, constraints: { id: /.*/ } do
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

  get 'wizards' => 'wizard#get_wizard_index'
  get 'wizards/:wizard_id' => 'wizard#get_wizard'
  post 'courses/:course_id/wizard/:wizard_id' => 'wizard#submit_wizard',
       constraints: { course_id: /.*/ }

  get 'courses' => 'courses#index'
  get 'talk' => 'courses#talk'
  get 'courses/*id' => 'courses#show', :as => :show, constraints: { id: /.*/ }

  root to: 'courses#index'

  # Route aliases for React frontend
  get '/course_creator(/*any)' => 'courses#index'

  match '/404', to: 'errors#file_not_found', via: :all
  match '/422', to: 'errors#unprocessable', via: :all
  match '/500', to: 'errors#internal_server_error', via: :all
end
