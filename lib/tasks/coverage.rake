# frozen_string_literal: true

namespace :generate do
  namespace :coverage do
    desc 'Generates the assets for coverage'
    task :assets do
      # The yarn build output is moved to tmp_build for recovery after tests
      Rake::Task['move:assets:to_tmp'].execute

      puts 'Generating coverage assets…'
      `yarn coverage`
      puts 'Coverage assets generated.'

      # Instruments the coverage assets
      Rake::Task['assets:coverage'].execute
    end

    desc 'Generates the coverage report'
    task :report do
      `java -jar JSCover/JSCover-all.jar -gf public/js_coverage`
      # The report can be viewed by running the rails server `rails s`
      # and visiting localhost:3000/js_coverage/jscoverage.html
    end
  end
end

namespace :move do
  namespace :assets do
    desc 'Moves the yarn build output to temporary folder'
    task :to_tmp do
      `rm -rf tmp_build` # Remove stale build assets
      `mkdir tmp_build` # Create an empty directory
      `cp -r public/assets/* tmp_build` # Copy production build assets to tmp_build
    end

    desc 'Moves the yarn build output back to the public folder'
    task :to_public do
      `rm -rf public/assets` # Remove stale build assets
      `mkdir public/assets` # Create an empty directory
      `cp -r tmp_build/* public/assets` # Recover the production build assets stored in tmp_build
    end
  end
end
