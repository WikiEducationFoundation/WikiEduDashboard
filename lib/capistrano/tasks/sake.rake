desc "Invoke rake task"
  task :sake do
    on roles(:app), in: :sequence, wait: 5 do
      within release_path do
        execute :rake, ENV['task']
      end
    end
  end