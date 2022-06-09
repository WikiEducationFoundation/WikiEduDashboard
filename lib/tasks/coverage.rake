# frozen_string_literal: true

namespace :generate do
  namespace :coverage do
    desc 'Splits the modules in main.js into their own files'
    task :split do
      puts 'Separating the modules…'
      counter = 0
      filenames = []
      main = 'public/assets/javascripts/main.js'
      text = File.read(main)
      funs = text.scan(%r/![*]{3}.*[*]{3}!(?:.|\n)*?\/[*]{3}\/ \}\)/)
      # The above Regex matches the individual modules in the concatenated main.js
      funs.each do |fun|
        counter += 1
        text = text.sub(fun, "*/module_#{counter}") # Replaces the function with module_{number}
        fun = fun.gsub(%r/\/[*]{3}\/ \(/, "var module_#{counter} = (")
        # The above names the individual modules in the format module_{number}
        filename = File
                   .basename(fun.scan(/![*]{3}(.*)[*]{3}!/).second.first.squish, '.*')
                   .gsub(/\W/, '') + "_#{counter}"
        filenames << filename
        File.open("public/assets/javascripts/#{filename}.js", 'w') do |file|
          file.write("/*#{fun}")
        end
      end
      File.write(main, text) # Replace main.js file with modules in the form of module_{number}
      File.open('modules.txt', 'w') do |file|
        file.write(filenames.join("\n")) # Store the module file names for loading via <script>
      end
      puts 'Modules separated.'
    end

    desc 'Generates the assets for coverage'
    task :assets do
      # The yarn build output is moved to tmp_build for recovery after tests
      Rake::Task['move:assets:to_tmp'].execute

      puts 'Generating coverage assets…'
      `yarn coverage`
      puts 'Coverage assets generated.'

      # Split the modules in main.js into their own files
      Rake::Task['generate:coverage:split'].execute

      # Instruments the coverage assets
      Rake::Task['assets:coverage'].execute
    end

    desc 'Generates the coverage report'
    task :report do
      puts 'Generating report…'
      `java -jar JSCover/JSCover-all.jar -gf public/js_coverage`
      # The report can be viewed by running the rails server `rails s`
      # and visiting localhost:3000/js_coverage/jscoverage.html
      puts 'Reports generated.'
      puts 'Visit http://localhost:3000/js_coverage/jscoverage.html to view the report'
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
