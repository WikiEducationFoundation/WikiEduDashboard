# frozen_string_literal: true

module Errors
  module AuthenticationErrors
    class NotSignedInError < StandardError
      def initialize(msg='Please sign in.')
        super
      end
    end # NotSignedInError

    class NotPermittedError < StandardError
      def initialize(msg='You are not permitted to do that.')
        super
      end
    end # NotPermittedError

    class NotAdminError < StandardError
      def initialize(msg='Only administrators may do that.')
        super
      end
    end # NotAdmitError

    class ParticipatingUserError < StandardError
      def initialize(msg='Only participants of this course may do that.')
        super
      end
    end # ParticipatingUserError
  end # AuthenticationErrors
end # Errors
