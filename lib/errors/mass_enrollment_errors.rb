# frozen_string_literal: true

module Errors
  module MassEnrollmentErrors
    class TooManyUsersError < StandardError
      TOO_MANY_MESSAGE = <<~TOO_MANY
        This exceeds the maximum number of users for mass enrollment. For tracking large groups,
        consider using Event Metrics instead: https://eventmetrics.wmflabs.org/
      TOO_MANY

      def initialize(msg = TOO_MANY_MESSAGE)
        super
      end
    end
  end
end
