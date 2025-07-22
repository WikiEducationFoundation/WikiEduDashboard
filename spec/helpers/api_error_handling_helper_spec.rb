# frozen_string_literal: true

require 'rails_helper'
require './lib/errors/api_error_handling'
require './lib/errors/update_service_error_helper'

class DummyUpdateService
  include UpdateServiceErrorHelper

  def initialize
    @course = OpenStruct.new(slug: 'test-course-slug') # Mock course with a slug
  end
end

RSpec.describe ApiErrorHandling do
  subject do
    Class.new do
      include ApiErrorHandling

      # Define a mock TYPICAL_ERRORS constant for testing
      const_set(:TYPICAL_ERRORS, [StandardError])  # Mocking TYPICAL_ERRORS
    end.new
  end

  let(:dummy_update_service) { DummyUpdateService.new }
  let(:error) { StandardError.new('Test error') }

  describe '#log_error' do
    it 'increments error_count by 1 if no new_errors_count is provided' do
      sentry_extra = {}
      expect do
        subject.log_error(error, update_service: dummy_update_service, sentry_extra:)
      end
        .to change(dummy_update_service, :error_count).by(1)
    end

    it 'increments error_count by the provided new_errors_count' do
      sentry_extra = { new_errors_count: 3 }
      expect do
        subject.log_error(error, update_service: dummy_update_service, sentry_extra:)
      end
        .to change(dummy_update_service, :error_count).by(3)
    end

    it 'handles a missing sentry_extra argument and defaults to 1' do
      expect { subject.log_error(error, update_service: dummy_update_service) }
        .to change(dummy_update_service, :error_count).by(1)
    end
  end
end
