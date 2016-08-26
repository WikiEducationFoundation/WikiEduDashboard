# frozen_string_literal: true

# Extra error handling for the development environment
module Errors
  module RescueDevelopmentErrors
    def self.included(base)
      rescue_from_rev_manifest(base)
      rescue_from_no_cohorts(base)
    end

    REV_MANIFEST_EXPLANATION =
      '  This error occurs when the asset build process has not generated '\
      'the required rev-manifest.json files, which specify the filenames '\
      'of the compiled stylesheet and javascript files.'\
      "\n\n  "\
      'Run `gulp` or `gulp build` and make sure there are no build errors.'
    def self.rescue_from_rev_manifest(base)
      base.rescue_from ActionView::Template::Error do |e|
        raise e unless e.message =~ /rev-manifest.json/
        explanation = String.new(e.message) + "\n\n"
        explanation << REV_MANIFEST_EXPLANATION

        render plain: explanation,
               status: 500
      end
    end

    NO_COHORTS_EXPLANATION =
      'Error: The default cohort does not exist.' \
      "\n\n" \
      'Run `rake cohort:add_cohorts` or go to "/cohorts" to create one called ' \
      "#{ENV['default_cohort']}."
    def self.rescue_from_no_cohorts(base)
      base.rescue_from CoursesPresenter::NoCohortError do
        render plain: NO_COHORTS_EXPLANATION,
               status: 500
      end
    end
  end
end
