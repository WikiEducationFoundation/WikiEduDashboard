# frozen_string_literal: true

# Extra error handling for the development environment
module Errors
  module RescueDevelopmentErrors
    def self.included(base)
      rescue_from_rev_manifest(base)
      rescue_from_no_campaigns(base)
    end

    REV_MANIFEST_EXPLANATION =
      '<p>This error occurs when the asset build process has not generated '\
      'the required rev-manifest.json files, which specify the filenames '\
      'of the compiled stylesheet and javascript files.</p>'\
      '<p>Run `gulp` or `gulp build` and make sure there are no build errors.</p>'
    def self.rescue_from_rev_manifest(base)
      base.rescue_from ActionView::Template::Error do |e|
        raise e unless e.message =~ /rev-manifest.json/
        explanation = '<p><code>' + String.new(e.message) + '</p></code>'
        explanation << REV_MANIFEST_EXPLANATION

        render plain: explanation,
               status: :internal_server_error
        raise StandardError, explanation if Rails.env.test?
      end
    end

    def self.rescue_from_no_campaigns(base)
      base.rescue_from CoursesPresenter::NoCampaignError do
        Campaign.create(title: 'Default Campaign', slug: ENV['default_campaign'])
        redirect_to '/'
      end
    end
  end
end
