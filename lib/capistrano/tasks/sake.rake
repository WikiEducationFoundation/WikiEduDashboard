# frozen_string_literal: true

desc 'Invoke rake task'
task :sake do
  on roles(:app), in: :sequence, wait: 5 do
    within release_path do
      with rails_env: fetch(:rails_env) do
        execute :rake, ENV['task'], "RAILS_ENV=#{fetch(:rails_env)}"
      end
    end
  end
end
