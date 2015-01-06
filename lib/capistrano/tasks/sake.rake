desc "Invoke rake task"
  task :invoke do
    within release_path do
      execute :rake, ENV['task'], "RAILS_ENV=#{rails_env}"
    end
  end