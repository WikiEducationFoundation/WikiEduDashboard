# frozen_string_literal: true

module Errors
  module RescueErrors
    AUTHENTICATION_ERRORS = %i[not_signed_in not_permitted not_admin participating_user].freeze

    def self.included(base)
      rescue_invalid_token(base)
      rescue_unknown_format(base)

      ##
      # dynamically include each rescue method
      AUTHENTICATION_ERRORS.each do |err|
        send("rescue_#{err}", base)
      end
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

    ##
    # dynamically define each rescue in terms of the exception it will catch
    AUTHENTICATION_ERRORS.each do |err|
      send(:define_singleton_method, "rescue_#{err}") do |base|
        base.rescue_from "Errors::AuthenticationErrors::#{err.to_s.camelcase}Error".constantize do |e|
          respond_to do |format|
            format.json { render_json e.message }
            # format.html {} what happens here?
          end
        end # rescue_from
      end # send
    end # loop

    private

    def render_json msg
      render json: { message: msg },
             status: :unprocessable_entity
    end

  end # RescueErrors
end

