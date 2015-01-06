desc "Invoke rake task"
  task :invoke do
    run "cd #{deploy_to}/current"
    run "bundle exec rake #{ENV['task']} RAILS_ENV=#{rails_env}"
  end