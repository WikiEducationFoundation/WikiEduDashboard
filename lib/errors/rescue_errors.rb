# frozen_string_literal: true

module Errors
  module RescueErrors
    def self.included(base)
      ##
      # dynamically include each rescue method
      # When implementing a new rescue, add its base name here (minus the _rescue part).
      rescues = %i[invalid_token unknown_format not_signed_in not_permitted not_admin
                   participating_user].freeze
      rescues.each do |err|
        send("rescue_#{err}", base)
      end
    end

    def self.rescue_invalid_token(base)
      base.rescue_from ActionController::InvalidAuthenticityToken do
        if json?(request)
          render json: { message: t('error_401.json_explanation') }, status: :unauthorized
        else
          render plain: t('error_401.explanation'), status: :unauthorized
        end
      end
    end

    def self.rescue_unknown_format(base)
      # Stop index.php routes from causing the kinds of errors that get reported
      # to Sentry.
      base.rescue_from ActionController::UnknownFormat do
        render plain: t('error_404.explanation'), status: :not_found
      end
    end

    def self.rescue_not_signed_in(base)
      base.rescue_from AuthenticationErrors::NotSignedInError do |e|
        if json?(request)
          render json: { message: e.message }, status: :unauthorized
        else
          # TODO: need more user friendly error handling for html
          render plain: e.message, status: :unauthorized
        end
      end
    end

    def self.rescue_not_permitted(base)
      base.rescue_from AuthenticationErrors::NotPermittedError do |e|
        if json?(request)
          render json: { message: e.message }, status: :unauthorized
        else
          # TODO: need more user friendly error handling for html
          render plain: e.message, status: :unauthorized
        end
      end
    end

    def self.rescue_not_admin(base)
      base.rescue_from AuthenticationErrors::NotAdminError do |e|
        if json?(request)
          render json: { message: e.message }, status: :unauthorized
        else
          # TODO: need more user friendly error handling for html
          render plain: e.message, status: :unauthorized
        end
      end
    end

    def self.rescue_participating_user(base)
      base.rescue_from AuthenticationErrors::ParticipatingUserError do |e|
        if json?(request)
          render json: { message: e.message }, status: :unauthorized
        else
          # TODO: need more user friendly error handling for html
          render plain: e.message, status: :unauthorized
        end
      end
    end

    private

    def json?(request)
      return true if request.format.to_s.include? 'json'
      request.fullpath.include? '.json'
    end
  end
end
