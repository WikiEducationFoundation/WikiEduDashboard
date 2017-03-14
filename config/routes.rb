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

  #UserProfilesController
  controller :user_profiles do
    get 'users/:username' => 'user_profiles#show' , constraints: { username: /.*/ }
    get 'user_stats' => 'user_profiles#stats_data'
    post 'users/update/:username' => 'user_profiles#update'
  end

  # Users
  resources :users, only: [:index, :show], param: :username, constraints: { username: /.*/ } do
    collection do
      get 'revisions'
    end
  end

  resources :assignments

  get 'mass_enrollment/:course_id'  => 'mass_enrollment#index',
      constraints: { course_id: /.*/ }
  post 'mass_enrollment/:course_id'  => 'mass_enrollment#add_users',
      constraints: { course_id: /.*/ }

  # Self-enrollment: joining a course by entering a passcode or visiting a url
  get 'courses/:course_id/enroll/:passcode' => 'self_enrollment#enroll_self',
      constraints: { course_id: /.*/ }

  # Courses
  controller :courses do
    get 'courses/new' => 'courses#new',
        constraints: { id: /.*/ } # repeat of resources

    get 'courses/*id/manual_update' => 'courses#manual_update',
        :as => :manual_update, constraints: { id: /.*/ }
    get 'courses/*id/notify_untrained' => 'courses#notify_untrained',
        :as => :notify_untrained, constraints: { id: /.*/ }
    get 'courses/*id/needs_update' =>  'courses#needs_update',
        :as => :needs_update, constraints: { id: /.*/ }
    get 'courses/*id/check' => 'courses#check',
        :as => :check, constraints: { id: /.*/ }
    match 'courses/*id/campaign' => 'courses#list',
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
    post 'clone_course/:id' => 'course_clone#clone'
    post 'courses/:id/update_syllabus' => 'courses#update_syllabus'
  end

  get 'lookups/campaign(.:format)' => 'lookups#campaign'
  get 'lookups/tag(.:format)' => 'lookups#tag'
  get 'lookups/article(.:format)' => 'lookups#article'

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

  get 'articles/article_data' => 'articles#article_data'
  get 'articles/details' => 'articles#details'

  resources :courses_users, only: [:index]
  resources :alerts, only: [:create] do
    member do
      put 'resolve'
    end
  end

  # Article Finder
  if Features.enable_article_finder?
    get 'article_finder(/*any)' => 'article_finder#index'
    post 'article_finder(/*any)' => 'article_finder#results'
  end

  # Reports and analytics
  get 'analytics(/*any)' => 'analytics#index'
  post 'analytics(/*any)' => 'analytics#results'

  # Campaigns
  resources :campaigns, param: :slug, except: :show do
    member do
      get 'overview'
      get 'programs'
      get 'students'
      get 'instructors'
      get 'courses'
      put 'add_organizer'
      put 'remove_organizer'
      put 'remove_course'
    end
  end
  get 'campaigns/:slug.json',
      controller: :campaigns,
      action: :show
  get 'campaigns/:slug', to: redirect('campaigns/%{slug}/programs')

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


  # Revision Feedback
  if Features.enable_revision_feedback?
    get 'revision_feedback/:rev_id' => 'revision_feedback#index'
  end

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
  get 'reload_trainings' => 'training#reload'

  get 'training_status' => 'training_status#show'

  # for React
  get 'training/:library_id/:module_id(/*any)' => 'training#slide_view'

  # API for slides for a module
  get 'training_modules' => 'training_modules#index'
  get 'training_module' => 'training_modules#show'


  # Misc
  # get 'courses' => 'courses#index'
  get 'explore' => 'explore#index'
  get 'unsubmitted_courses' => 'unsubmitted_courses#index'
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
  post '/survey_assignments/:id/send_test_email' => 'survey_assignments#send_test_email', as: 'send_test_email'
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
  get '/surveys/:id/optout' => 'surveys#optout', as: 'optout'
  get '/surveys/select_course/:id' => 'surveys#course_select'
  put '/survey_notification' => 'survey_notifications#update'
  post '/survey_notification/create' => 'survey_assignments#create_notifications', as: 'create_notifications'
  post '/survey_notification/send' => 'survey_assignments#send_notifications', as: 'send_notifications'

  # Onboarding
  get 'onboarding(/*any)' => 'onboarding#index', as: :onboarding
  put 'onboarding/onboard' => 'onboarding#onboard', as: :onboard

  # Update Locale Preference
  post '/update_locale/:locale' => 'users#update_locale', as: :update_locale

  # Route aliases for React frontend
  get '/course_creator(/*any)' => 'dashboard#index', as: :course_creator

  get '/feedback' => 'feedback_form_responses#new', as: :feedback
  get '/feedback_form_responses' => 'feedback_form_responses#index'
  get '/feedback_form_responses/:id' => 'feedback_form_responses#show', as: :feedback_form_response
  post '/feedback_form_responses' => 'feedback_form_responses#create'
  get '/feedback/confirmation' => 'feedback_form_responses#confirmation'

  # Chat
  if Features.enable_chat?
    get '/chat/login' => 'chat#login'
    put '/chat/enable_for_course/:course_id' => 'chat#enable_for_course'
  end

  # Salesforce
  if true # Features.wiki_ed?
    put '/salesforce/link/:course_id' => 'salesforce#link'
  end

  resources :admin
  resources :alerts_list

  require 'sidekiq/web'
  authenticate :user, lambda { |u| u.admin? } do
    mount Sidekiq::Web => '/sidekiq'
  end

  get '/styleguide' => 'styleguide#index'

  # Errors
  match '/404', to: 'errors#file_not_found', via: :all
  match '/422', to: 'errors#unprocessable', via: :all
  match '/599', to: 'errors#login_error', via: :all
  match '/500', to: 'errors#internal_server_error', via: :all
end
