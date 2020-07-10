# Page titles on Wikipedia may include dots, so this constraint is needed.

Rails.application.routes.draw do
  get 'errors/file_not_found'
  get 'errors/unprocessable'
  get 'errors/login_error'
  get 'errors/internal_server_error'
  get 'errors/incorrect_passcode'
  put 'errors/incorrect_passcode'

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

  get '/settings/all_admins' => 'settings#all_admins'
  post '/settings/upgrade_admin' => 'settings#upgrade_admin'
  post '/settings/downgrade_admin' => 'settings#downgrade_admin'

  get '/settings/special_users' => 'settings#special_users'
  post '/settings/upgrade_special_user' => 'settings#upgrade_special_user'
  post '/settings/downgrade_special_user' => 'settings#downgrade_special_user'

  post '/settings/update_salesforce_credentials' => 'settings#update_salesforce_credentials'
  # Griddler allows us to receive incoming emails. By default,
  # the path for incoming emails is /email_processor
  mount_griddler

  #UserProfilesController
  controller :user_profiles do
    get 'users/:username' => 'user_profiles#show' , constraints: { username: /.*/ }
    get 'user_stats' => 'user_profiles#stats'
    get 'stats_graphs' => 'user_profiles#stats_graphs'
    delete 'profile_image' => 'user_profiles#delete_profile_image', as: 'delete_profile_image', constraints: { username: /.*/ }
    get 'update_email_preferences/:username' => 'user_profiles#update_email_preferences', constraints: { username: /.*/ }
    post 'users/update/:username' => 'user_profiles#update' , constraints: { username: /.*/ }
  end

  #PersonalDataController
  controller :personal_data do
    get 'download_personal_data' => 'personal_data#show'
  end

  # Users
  resources :users, only: [:index, :show], param: :username, constraints: { username: /.*/ } do
    collection do
      get 'revisions'
    end
  end

  resources :assignments do
    patch '/status' => 'assignments#update_status'
    resources :assignment_suggestions
  end

  get 'mass_enrollment/:course_id'  => 'mass_enrollment#index',
      constraints: { course_id: /.*/ }
  post 'mass_enrollment/:course_id'  => 'mass_enrollment#add_users',
      constraints: { course_id: /.*/ }

  get '/requested_accounts_campaigns/*campaign_slug/create' => 'requested_accounts_campaigns#create_accounts',
      constraints: { campaign_slug: /.*/ }
  put '/requested_accounts_campaigns/*campaign_slug/enable_account_requests' => 'requested_accounts_campaigns#enable_account_requests',
      constraints: { campaign_slug: /.*/ }
  put '/requested_accounts_campaigns/*campaign_slug/disable_account_requests' => 'requested_accounts_campaigns#disable_account_requests',
      constraints: { campaign_slug: /.*/ }
  get '/requested_accounts_campaigns/*campaign_slug' => 'requested_accounts_campaigns#index',
      constraints: { campaign_slug: /.*/ }

  put 'requested_accounts' => 'requested_accounts#request_account'
  delete 'requested_accounts/*course_slug/*id/delete' => 'requested_accounts#destroy',
      constraints: { course_slug: /.*/ }
  post 'requested_accounts/*course_slug/create' => 'requested_accounts#create_accounts',
      constraints: { course_slug: /.*/ }
  get 'requested_accounts/*course_slug/enable_account_requests' => 'requested_accounts#enable_account_requests',
      constraints: { course_slug: /.*/ }
  get 'requested_accounts/:course_slug' => 'requested_accounts#show',
      constraints: { course_slug: /.*/ }
  get '/requested_accounts' => 'requested_accounts#index'
  post '/requested_accounts' => 'requested_accounts#create_all_accounts'

  # Self-enrollment: joining a course by entering a passcode or visiting a url
  get 'courses/:course_id/enroll/(:passcode)' => 'self_enrollment#enroll_self',
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
    get 'courses/*id/ores_plot' =>  'ores_plot#course_plot',
        constraints: { id: /.*/ }
    get 'courses/*id/refresh_ores_data' =>  'ores_plot#refresh_ores_data',
        :as => :refresh_ores_data, constraints: { id: /.*/ }
    get 'courses/*id/check' => 'courses#check',
        :as => :check, constraints: { id: /.*/ }
    match 'courses/*id/campaign' => 'courses#list',
          constraints: { id: /.*/ }, via: [:post, :delete]
    match 'courses/*id/tag' => 'courses#tag',
          constraints: { id: /.*/ }, via: [:post, :delete]
    match 'courses/*id/user' => 'users#enroll',
          constraints: { id: /.*/ }, via: [:post, :delete]

    # show-type actions: first all the specific json endpoints,
    # then the catchall show endpoint
    get 'courses/:slug/course.json' => 'courses#course',
        constraints: { slug: /.*/ }
    get 'courses/:slug/articles.json' => 'courses#articles',
        constraints: { slug: /.*/ }
    get 'courses/:slug/revisions.json' => 'courses#revisions',
        constraints: { slug: /.*/ }
    get 'courses/:slug/users.json' => 'courses#users',
        constraints: { slug: /.*/ }
    get 'courses/:slug/assignments.json' => 'courses#assignments',
        constraints: { slug: /.*/ }
    get 'courses/:slug/campaigns.json' => 'courses#campaigns',
        constraints: { slug: /.*/ }
    get 'courses/:slug/categories.json' => 'courses#categories',
        constraints: { slug: /.*/ }
    get 'courses/:slug/tags.json' => 'courses#tags',
        constraints: { slug: /.*/ }
    get 'courses/:slug/timeline.json' => 'courses#timeline',
        constraints: { slug: /.*/ }
    get 'courses/:slug/uploads.json' => 'courses#uploads',
        constraints: { slug: /.*/ }
    get 'courses/:school/:titleterm(/:_subpage(/:_subsubpage(/:_subsubsubpage)))' => 'courses#show',
        :as => 'show',
        constraints: {
          school: /[^\/]*/,
          titleterm: /[^\/]*/
        }

    get 'embed/course_stats/:school/:titleterm(/:_subpage(/:_subsubpage))' => 'embed#course_stats',
    constraints: {
        school: /[^\/]*/,
        titleterm: /[^\/]*/
    }

    post 'clone_course/:id' => 'course_clone#clone', as: 'course_clone'
    post 'courses/:id/update_syllabus' => 'courses/syllabuses#update'
    delete 'courses/:id/delete_all_weeks' => 'courses#delete_all_weeks',
      constraints: {
        id: /.*/
      }
  end

  # Categories
  post 'categories' => 'categories#add_category'
  delete 'categories' => 'categories#remove_category'

  get 'lookups/campaign(.:format)' => 'lookups#campaign'
  get 'lookups/tag(.:format)' => 'lookups#tag'

  # Timeline
  resources :courses, constraints: { id: /.*/ } do
    resources :weeks, only: [:index, :new, :create], constraints: { id: /.*/ }
    # get 'courses' => 'courses#index'
  end
  resources :weeks, only: [:index, :show, :edit, :update, :destroy]
  resources :blocks, only: [:show, :edit, :update, :destroy]
  post 'courses/:course_id/timeline' => 'timeline#update_timeline',
       constraints: { course_id: /.*/ }
  post 'courses/:course_id/enable_timeline' => 'timeline#enable_timeline',
       constraints: { course_id: /.*/ }
  post 'courses/:course_id/disable_timeline' => 'timeline#disable_timeline',
       constraints: { course_id: /.*/ }

  get 'revisions' => 'revisions#index'

  get 'articles/article_data' => 'articles#article_data'
  get 'articles/details' => 'articles#details'
  post 'articles/status' => 'articles#update_tracked_status'

  resources :courses_users, only: [:index]
  resources :alerts, only: [:create] do
    member do
      get 'resolve'
      put 'resolve'
    end
  end

  put 'greeting' => 'greeting#greet_course_students'

  # Article Finder
  get 'article_finder' => 'article_finder#index'

  # Reports and analytics
  get 'analytics(/*any)' => 'analytics#index'
  post 'analytics(/*any)' => 'analytics#results'
  get 'usage' => 'analytics#usage'
  get 'ungreeted' => 'analytics#ungreeted'
  get 'course_csv' => 'analytics#course_csv'
  get 'course_edits_csv' => 'analytics#course_edits_csv'
  get 'course_uploads_csv' => 'analytics#course_uploads_csv'
  get 'course_students_csv' => 'analytics#course_students_csv'
  get 'course_articles_csv' => 'analytics#course_articles_csv'
  get 'course_revisions_csv' => 'analytics#course_revisions_csv'
  get 'all_courses_csv' => 'analytics#all_courses_csv'

  # Campaigns
  resources :campaigns, param: :slug, except: :show do
    member do
      get 'overview'
      get 'programs'
      get 'articles'
      get 'users'
      get 'assignments'
      get 'students'
      get 'instructors'
      get 'courses'
      get 'ores_plot'
      get 'articles_csv'
      get 'revisions_csv'
      get 'alerts'
      put 'add_organizer'
      put 'remove_organizer'
      put 'remove_course'
    end
  end

  get 'campaigns/:slug.json',
      controller: :campaigns,
      action: :show
  get 'campaigns/:slug', to: redirect('campaigns/%{slug}/programs')
  get 'campaigns/:slug/programs/:courses_query',
      controller: :campaigns,
      action: :programs,
      to: 'campaigns/%{slug}/programs?courses_query=%{courses_query}'
  get 'campaigns/:slug/ores_data.json' =>  'ores_plot#campaign_plot'

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
  get '/revision_feedback' => 'revision_feedback#index'

  # Wizard
  get 'wizards' => 'wizard#wizard_index'
  get 'wizards/:wizard_id' => 'wizard#wizard'
  post 'courses/:course_id/wizard/:wizard_id' => 'wizard#submit_wizard',
       constraints: { course_id: /.*/ }

  # Training
  get 'training' => 'training#index'
  get 'training/:library_id' => 'training#show', as: :training_library
  get 'training/:library_id/:module_id' => 'training#training_module', as: :training_module
  get 'training_modules_users' => 'training_modules_users#index'
  post 'training_modules_users' => 'training_modules_users#create_or_update'
  post 'training_modules_users/exercise' => 'training_modules_users#mark_exercise_complete'
  get 'reload_trainings' => 'training#reload'

  get 'training_status' => 'training_status#show'
  get 'user_training_status' => 'training_status#user'

  # for React
  get 'training/:library_id/:module_id(/*any)' => 'training#slide_view'

  # API for slides for a module
  get 'training_modules' => 'training_modules#index'
  get 'training_module' => 'training_modules#show'


  # Misc
  # get 'courses' => 'courses#index'
  get 'explore' => 'explore#index'
  get 'unsubmitted_courses' => 'unsubmitted_courses#index'
  get 'active_courses' => 'active_courses#index'
  get '/courses_by_wiki/:language.:project(.org)' => 'courses_by_wiki#show'

  # frequenty asked questions
  resources :faq
  get '/faq_topics' => 'faq_topics#index'
  get '/faq_topics/new' => 'faq_topics#new'
  post '/faq_topics' => 'faq_topics#create'
  get '/faq_topics/:slug/edit' => 'faq_topics#edit'
  post '/faq_topics/:slug' => 'faq_topics#update'
  delete '/faq_topics/:slug' => 'faq_topics#delete'

  # Authenticated users root to the courses dashboard
  authenticated :user do
    root to: "dashboard#index", as: :courses_dashboard
  end

  get 'dashboard' => 'dashboard#index'
  get 'my_account' => 'dashboard#my_account'

  # Unauthenticated users root to the home page
  root to: 'home#index'

  # Surveys
  mount Rapidfire::Engine => "/surveys/rapidfire", :as => 'rapidfire'
  get '/surveys/results' => 'surveys#results_index', as: 'results'
  resources :survey_assignments, path: 'surveys/assignments'
  post '/survey_assignments/:id/send_test_email' => 'survey_assignments#send_test_email', as: 'send_test_email'
  put '/surveys/question_position' => 'questions#update_position'
  get '/survey/results/:id' => 'surveys#results', as: 'survey_results'
  get '/survey/question/results/:id' => 'questions#results', as: 'question_results'
  get '/surveys/question_group_question/:id' => 'questions#question'
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
  get '/survey/responses' => 'survey_responses#index'
  delete '/survey/responses/:id/delete' => 'survey_responses#delete'

  # Onboarding
  get 'onboarding(/*any)' => 'onboarding#index', as: :onboarding
  put 'onboarding/onboard' => 'onboarding#onboard', as: :onboard
  put 'onboarding/supplementary' => 'onboarding#supplementary', as: :supplementary

  # Update Locale Preference
  post '/update_locale/:locale' => 'users/locale#update_locale', as: :update_locale
  get '/update_locale/:locale' => 'users/locale#update_locale'

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
  if Features.wiki_ed?
    put '/salesforce/link/:course_id' => 'salesforce#link'
    put '/salesforce/update/:course_id' => 'salesforce#update'
    get '/salesforce/create_media' => 'salesforce#create_media'
  end

  # Experiments
  namespace :experiments do
    get 'fall2017_cmu_experiment/:course_id/:email_code/opt_in' => 'fall2017_cmu_experiment#opt_in'
    get 'fall2017_cmu_experiment/:course_id/:email_code/opt_out' => 'fall2017_cmu_experiment#opt_out'
    get 'fall2017_cmu_experiment/course_list' => 'fall2017_cmu_experiment#course_list'
    get 'spring2018_cmu_experiment/:course_id/:email_code/opt_in' => 'spring2018_cmu_experiment#opt_in'
    get 'spring2018_cmu_experiment/:course_id/:email_code/opt_out' => 'spring2018_cmu_experiment#opt_out'
    get 'spring2018_cmu_experiment/course_list' => 'spring2018_cmu_experiment#course_list'
  end

  resources :admin
  resources :alerts_list

  namespace :mass_email do
    get 'term_recap' => 'term_recap#index'
    post 'term_recap/send' => 'term_recap#send_recap_emails'
  end

  get '/redirect/sandbox/:sandbox' => 'redirects#sandbox'

  resources :settings, only: [:index]

  authenticate :user, lambda { |u| u.admin? } do
    post '/tickets/reply' => 'tickets#reply', format: false
    post '/tickets/notify_owner' => 'tickets#notify_owner', format: false
    get '/tickets/*dashboard' => 'tickets#dashboard', format: false
    mount TicketDispenser::Engine, at: "/td"
  end

  require 'sidekiq_unique_jobs/web'
  authenticate :user, lambda { |u| u.admin? } do
    mount Sidekiq::Web => '/sidekiq'
  end

  get '/private_information' => 'about_this_site#private_information'
  get '/styleguide' => 'styleguide#index'

  # Errors
  match '/404', to: 'errors#file_not_found', via: :all
  match '/422', to: 'errors#unprocessable', via: :all
  match '/599', to: 'errors#login_error', via: :all
  match '/500', to: 'errors#internal_server_error', via: :all
end
