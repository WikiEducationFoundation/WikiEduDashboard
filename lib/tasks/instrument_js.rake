namespace :assets do
  desc 'Instrument all javascript in place'
  task :coverage do
    Rake::Task["assets:coverage:primary"].execute
  end

  namespace :coverage do
    def jscoverage_loc
      # Location for JSCover jar
      'JSCover/JSCover-all.jar'
    end

    def instrumentalize
      config = Rails.application.config
      target=File.join(Rails.public_path,config.assets.prefix)+'/javascripts' # public/assets/javascript

      `rm -rf #{tmp=File.join(Rails.root,'public','js_coverage')}` # Remove stale coverage reports
      
      puts "\nInstrumentalizing…"
      # The following command instruments the JS code in public/assets/javascript
      # except Sentry, jQuery, Vendors, TinyMCE, i18n files
      # At this point, the instrumented code is in public/js_coverage
      `java -Dfile.encoding=UTF-8 -jar #{jscoverage_loc} -fs #{target} #{tmp} --local-storage --no-instrument-reg=.*sentry.* --no-instrument-reg=.*jquery.* --no-instrument-reg=.*vendors.* --no-instrument-reg=.*tinymce.* --no-instrument-reg=.*i18n.*`
      
      # We copy the instrumented code to public/asssets/javascript which enables tests to run on instrumeted code
      puts 'Copying into place…'
      `cp -R #{tmp}/* #{target}`
    end

    task :primary => %w(assets:environment) do
      unless File.exist?("#{jscoverage_loc}")
        abort "Cannot find JSCover! Download from http://tntim96.github.io/JSCover/ and put JSCover-all.jar in #{jscoverage_loc}"
      end
      instrumentalize
    end
  end
end