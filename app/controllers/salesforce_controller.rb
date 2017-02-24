# frozen_string_literal: true
class SalesforceController < ApplicationController
  respond_to :json
  before_action :require_admin_permissions

  def link
    validate_salesforce_id
    @course = Course.find(params[:course_id])
    @course.flags[:salesforce_id] = params[:salesforce_id]
    @course.save
    PushCourseToSalesforce.new(@course)
    render json: { success: true, flags: @course.flags }
  end

  private

  # Valid Salesforce IDs are either 15 or 18 characters.
  VALID_SALESFORCE_ID_SIZES = [15, 18].freeze
  def validate_salesforce_id
    return if VALID_SALESFORCE_ID_SIZES.include? params[:salesforce_id].size
    raise InvalidSalesforceIdError
  end

  class InvalidSalesforceIdError < StandardError; end
end
