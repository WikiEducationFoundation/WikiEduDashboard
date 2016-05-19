# Page titles on Wikipedia may include dots, so this constraint is needed.

Rails.application.routes.draw do
  get 'errors/file_not_found'
  get 'errors/unprocessable'
  get 'errors/login_error'
  get 'errors/internal_server_error'
  get 'errors/incorrect_passcode'

  # Sessions
  devise_for :users, controllers: { omniauth_callbacks: 'omniauth_callbacks' }
  devise_scope :user do
    # OmniAuth may fall back to :new_user_session when the OAuth flow fails.
    # So, we treat it as a login error.
    get 'sign_in', to: 'errors#login_error', as: :new_user_session

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
    post 'courses/:id/update_syllabus' => 'courses#update_syllabus'
  end

  get 'lookups/(:action)(.:format)' => 'lookups'

  # Timeline
  resources :courses, constraints: { id: /.*/ } do
    resources :weeks, only: [:index, :new, :create], constraints: { id: /.*/ }
    # get 'courses' => 'courses#index'
  end
  resources :weeks, only: [:index, :show, :edit, :update, :destroy]
  resources :blocks, only: [:show, :edit, :update, :destroy]
  resources :gradeables, collection: { update_multiple: :put }
  post 'courses/:course_id/timeline' => 'timeline#update_timeline',
       constraints: { course_id: /.*/ }

  get 'revisions' => 'revisions#index'

  resources :courses_users, only: [:index]

  # Article Finder
  if Features.enable_article_finder?
    get 'article_finder(/*any)' => 'article_finder#index'
    post 'article_finder(/*any)' => 'article_finder#results'
  end

  # Reports and analytics
  get 'analytics(/*any)' => 'analytics#index'
  post 'analytics(/*any)' => 'analytics#results'

  # Cohort data
  controller :cohorts do
    get 'cohorts/:slug/students' => 'cohorts#students'
  end

  # Recent Activity
  get 'recent-activity/plagiarism/report' => 'recent_activity#plagiarism_report'
  get 'recent-activity(/*any)' => 'recent_activity#index', as: :recent_activity

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
  get 'revision_analytics/recent_uploads',
      controller: 'revision_analytics',
      action: 'recent_uploads'



  # Wizard
  get 'wizards' => 'wizard#wizard_index'
  get 'wizards/:wizard_id' => 'wizard#wizard'
  post 'courses/:course_id/wizard/:wizard_id' => 'wizard#submit_wizard',
       constraints: { course_id: /.*/ }

  # Training
  get 'training' => 'training#index'
  get 'training/:library_id' => 'training#show', as: :training_library
  get 'training/:library_id/:module_id' => 'training#training_module', as: :training_module
  post 'training_modules_users' => 'training_modules_users#create_or_update'

  # for React
  get 'training/:library_id/:module_id(/*any)' => 'training#slide_view'

  # API for slides for a module
  get 'training_modules' => 'training_modules#index'
  get 'training_module' => 'training_modules#show'


  # Misc
  # get 'courses' => 'courses#index'
  get 'explore' => 'explore#index'
  # get 'courses/*id' => 'courses#show', :as => :show, constraints: { id: /.*/ }

  # ask.wikiedu.org search box
  get 'ask' => 'ask#search'

  # Authenticated users root to the courses dashboard
  authenticated :user do
    root to: "dashboard#index", as: :courses_dashboard
  end

  # Unauthenticated users root to the home page
  root to: 'home#index'

  mount Rapidfire::Engine => "/surveys/rapidfire", :as => 'rapidfire'
  get '/surveys/results' => 'surveys#results_index', as: 'results'
  resources :survey_assignments, path: 'surveys/assignments'
  post '/surveys/clone/:id' => 'surveys#clone'
  put '/surveys/question_position' => 'questions#update_position'
  get '/survey/results/:id' => 'surveys#results', as: 'survey_results'
  get '/survey/question/results/:id' => 'questions#results', as: 'question_results'
  get '/surveys/question_group_question/:id' => 'questions#get_question'
  get '/surveys/:id/question_group' => 'surveys#edit_question_groups', :as => "edit_question_groups"
  post '/surveys/question_group/clone/:id' => 'surveys#clone_question_group'
  post '/surveys/question/clone/:id' => 'surveys#clone_question'
  post '/surveys/update_question_group_position' => 'surveys#update_question_group_position'
  resources :surveys
  get '/surveys/select_course/:id' => 'surveys#course_select'
  put '/survey_notification' => 'survey_notifications#update'
  post '/survey_notification/create' => 'survey_assignments#create_notifications', as: 'create_notifications'
  post '/survey_notification/send' => 'survey_assignments#send_notifications', as: 'send_notifications'

  # Onboarding
  get 'onboarding(/*any)' => 'onboarding#index', as: :onboarding
  put 'users/onboard' => 'users#onboard', as: :onboard

  # Route aliases for React frontend
  get '/course_creator(/*any)' => 'dashboard#index', as: :course_creator

  get '/feedback' => 'feedback_form_responses#new', as: :feedback
  get '/feedback_form_responses' => 'feedback_form_responses#index'
  get '/feedback_form_responses/:id' => 'feedback_form_responses#show', as: :feedback_form_response
  post '/feedback_form_responses' => 'feedback_form_responses#create'
  get '/feedback/confirmation' => 'feedback_form_responses#confirmation'

  # Errors
  match '/404', to: 'errors#file_not_found', via: :all
  match '/422', to: 'errors#unprocessable', via: :all
  match '/599', to: 'errors#login_error', via: :all
  match '/500', to: 'errors#internal_server_error', via: :all
end
