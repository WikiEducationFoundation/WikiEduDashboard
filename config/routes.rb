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

  resources :assignments

  # Self-enrollment: joining a course by entering a passcode or visiting a url
  get 'courses/:course_id/enroll/:passcode' => 'self_enrollment#enroll_self',
      constraints: { course_id: /.*/ }

  # Courses
  controller :courses do
    get 'courses/*id/get_wiki_top_section' => 'courses#get_wiki_top_section',
        :as => :get_wiki_top_section, constraints: { id: /.*/ }
    get 'courses/new' => 'courses#new',
        constraints: { id: /.*/ } # repeat of resources

    get 'courses/*id/manual_update' => 'courses#manual_update',
        :as => :manual_update, constraints: { id: /.*/ }
    get 'courses/*id/notify_untrained' => 'courses#notify_untrained',
        :as => :notify_untrained, constraints: { id: /.*/ }
    get 'courses/*id/notify_students(/:type)' => 'courses#notify_students',
        :as => :notify_students, constraints: { id: /.*/ }
    get 'courses/*id/update_course_talk' => 'courses#update_course_talk',
        :as => :update_course_talk, constraints: { id: /.*/ }

    get 'courses/*id/check' => 'courses#check',
        :as => :check, constraints: { id: /.*/ }
    match 'courses/*id/cohort' => 'courses#list',
          constraints: { id: /.*/ }, via: [:post, :delete]
    match 'courses/*id/tag' => 'courses#tag',
          constraints: { id: /.*/ }, via: [:post, :delete]
    match 'courses/*id/user' => 'users#enroll',
          constraints: { id: /.*/ }, via: [:post, :delete]

    get 'courses/:school/:titleterm(/:endpoint(/*any))' => 'courses#show',
        defaults: { endpoint: 'overview' }, :as => 'show',
        constraints: {
          school: /[^\/]*/,
          titleterm: /[^\/]*/
        }
    post 'clone_course/:id' => 'courses#clone'
  end

  get 'lookups/(:action)(.:format)' => 'lookups'

  # Assigning articles to students
  post 'courses/:course_id/users' => 'users#save_assignments',
       constraints: { course_id: /.*/ }

  # Timeline
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

  get 'revisions' => 'revisions#index'

  resources :weeks, only: [:index]
  resources :courses_users, only: [:index]

  # Article Finder
  if ENV['dashboard_url'] == 'outreachdashboard.wmflabs.org'
    get 'article_finder(/*any)' => 'article_finder#index'
    post 'article_finder(/*any)' => 'article_finder#results'
  end

  # Reports and analytics
  get 'analytics(/*any)' => 'analytics#index'
  post 'analytics(/*any)' => 'analytics#results'

  # Recent Activity
  get 'recent-activity(/*any)' => 'recent_activity#index'

  # Revision analytics JSON API for React
  get 'revision_analytics/dyk_eligible',
      controller: 'revision_analytics',
      action: 'dyk_eligible'
  get 'revision_analytics/suspected_plagiarism',
      controller: 'revision_analytics',
      action: 'suspected_plagiarism'
  get 'revision_analytics/recent_edits',
      controller: 'revision_analytics',
      action: 'recent_edits'

  # Wizard
  get 'wizards' => 'wizard#wizard_index'
  get 'wizards/:wizard_id' => 'wizard#wizard'
  post 'courses/:course_id/wizard/:wizard_id' => 'wizard#submit_wizard',
       constraints: { course_id: /.*/ }

  get 'training' => 'training#index'
  get 'training/:library_id' => 'training#show', as: :training_library
  get 'training/:library_id/:module_id' => 'training#training_module', as: :training_module

  # for React
  get 'training/:library_id/:module_id(/*any)' => 'training#slide_view'

  # API for slides for a module
  get 'training_modules' => 'training_modules#index'
  get 'training_module' => 'training_modules#show'
  get 'training_module_by_id' => 'training_modules#by_id'
  get 'training_module_for_block' => 'training_modules#for_block'


  # Misc
  get 'courses' => 'courses#index'
  get 'talk' => 'courses#talk'
  # get 'courses/*id' => 'courses#show', :as => :show, constraints: { id: /.*/ }

  # ask.wikiedu.org search box
  get 'ask' => 'ask#search'

  # Root
  root to: 'courses#index'

  # Route aliases for React frontend
  get '/course_creator(/*any)' => 'courses#index'

  # Errors
  match '/404', to: 'errors#file_not_found', via: :all
  match '/422', to: 'errors#unprocessable', via: :all
  match '/500', to: 'errors#internal_server_error', via: :all
end
