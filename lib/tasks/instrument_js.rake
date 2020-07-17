namespace :assets do
  desc 'Instrument all javascript in place'
  task :coverage do
    Rake::Task["assets:coverage:primary"].execute
  end

  namespace :coverage do
    def jscoverage_loc;'JSCover/';end
    def internal_instrumentalize
      config = Rails.application.config
      target=File.join(Rails.public_path,config.assets.prefix)+'/javascripts'

      `rm -rf #{tmp=File.join(Rails.root,'tmp','jscover')}`
      `mkdir #{tmp}`
      
      puts "\nInstrumentalizing…"
      `java -Dfile.encoding=UTF-8 -jar #{jscoverage_loc}target/dist/JSCover-all.jar -fs #{target} #{tmp} #{'--no-branch' unless ENV['C1']} --local-storage`
      puts 'Copying into place…'
      `cp -R #{tmp}/ #{target}`
      `rm -rf #{tmp}`
      File.open("#{target}/jscoverage.js",'a'){|f| f.puts 'jscoverage_isReport = true' }
    end

    task :primary => %w(assets:environment) do
      unless Dir.exist?(jscoverage_loc)
        abort "Cannot find JSCover! Download from: http://tntim96.github.io/JSCover/ and put in #{jscoverage_loc}"
      end
      internal_instrumentalize
    end
  end
end