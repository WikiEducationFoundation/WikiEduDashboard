# frozen_string_literal: true

module Errors
  module RescueErrors
    def self.included(base)
      rescue_invalid_token(base)
      rescue_unknown_format(base)
    end # self.included

    def self.rescue_invalid_token(base)
      base.rescue_from ActionController::InvalidAuthenticityToken do
        render plain: t('error_401.explanation'), status: :unauthorized
      end
    end # self.rescue_invalid_token

    def self.rescue_unknown_format(base)
      # Stop index.php routes from causing the kinds of errors that get reported
      # to Sentry.
      base.rescue_from ActionController::UnknownFormat do
        render plain: t('error_404.explanation'), status: 404
      end
    end # self.rescue_unknown_format

  end # RescueErrors
end

