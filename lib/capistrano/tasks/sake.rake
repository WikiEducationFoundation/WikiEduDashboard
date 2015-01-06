desc "Invoke rake task"
  task :sake do
    on roles(:app), in: :sequence, wait: 5 do
      within release_path do
        with rails_env: :production do
          execute :rake, ENV['task'], "RAILS_ENV=production"
        end
      end
    end
  end