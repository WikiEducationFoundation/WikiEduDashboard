# frozen_string_literal: true

# Extra error handling for the development environment
module Errors
  module RescueDevelopmentErrors
    REV_MANIFEST_EXPLANATION =
      '  This error occurs when the asset build process has not generated '\
      'the required rev-manifest.json files, which specify the filenames '\
      'of the compiled stylesheet and javascript files.'\
      "\n\n  "\
      'Run `gulp` or `gulp build` and make sure there are no build errors.'\

    def self.included(base)
      base.rescue_from ActionView::Template::Error do |e|
        raise e unless e.message =~ /rev-manifest.json/
        explanation = String.new(e.message) + "\n\n"
        explanation << REV_MANIFEST_EXPLANATION

        render plain: explanation,
               status: 500
      end
    end
  end
end
