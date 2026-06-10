# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/source_verification_example_store"

# Prototype page for the source verification exercise: serves a single
# harvested (claim, cited source) example and asks the student whether
# the source supports the claim. Responses are not yet persisted.
class SourceVerificationController < ApplicationController
  before_action :require_signed_in

  RESPONSE_OPTIONS = %w[supports does_not_support cannot_tell].freeze

  def show
    @example = find_example
  end

  def respond
    @example = find_example
    submitted = params[:response]
    @submitted_response = submitted if RESPONSE_OPTIONS.include?(submitted)
    render 'show'
  end

  private

  def find_example
    if params[:example_id].present?
      SourceVerificationExampleStore.find(params[:example_id])
    else
      SourceVerificationExampleStore.random
    end
  end
end
