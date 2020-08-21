# frozen_string_literal: true

namespace :assets do
  desc 'Instrument all javascript in place'
  task :coverage do
    unless File.exist?(jscoverage_loc)
      abort `Cannot find JSCover!
            Download from http://tntim96.github.io/JSCover/
            and put JSCover-all.jar in #{jscoverage_loc}`
    end
    instrumentalize
  end

  def jscoverage_loc
    # Location for JSCover jar
    'JSCover/JSCover-all.jar'
  end

  def no_instrument
    files = %w[sentry jquery vendors tinymce i18n]
    files.map { |path| "--no-instrument-reg=.*#{path}.*" }.join(' ')
  end

  def instrumentalize
    config = Rails.application.config
    target = File.join(Rails.public_path, config.assets.prefix) + '/javascripts'

    # Remove stale coverage reports
    `rm -rf #{tmp = File.join(Rails.root, 'public', 'js_coverage')}`

    puts 'Instrumentalizing…'

    # The following command instruments the JS code in public/assets/javascript
    # except Sentry, jQuery, Vendors, TinyMCE, i18n files
    # At this point, the instrumented code is in public/js_coverage

    # rubocop:disable Layout/LineLength
    `java -Dfile.encoding=UTF-8 -jar #{jscoverage_loc} -fs #{target} #{tmp} --local-storage #{no_instrument}`
    # rubocop:enable Layout/LineLength

    # We copy the instrumented code to public/asssets/javascript
    # which enables tests to run on instrumeted code
    puts 'Copying into place…'
    `cp -R #{tmp}/* #{target}`
  end
end
