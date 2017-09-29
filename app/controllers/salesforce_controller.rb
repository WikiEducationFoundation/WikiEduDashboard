# frozen_string_literal: true

class SalesforceController < ApplicationController
  respond_to :json, only: [:link]
  before_action :require_admin_permissions

  def link
    validate_salesforce_id
    @course = Course.find(params[:course_id])
    @course.flags[:salesforce_id] = params[:salesforce_id]
    @course.save
    PushCourseToSalesforce.new(@course)
    render json: { success: true, flags: @course.flags }
  end

  def update
    @course = Course.find(params[:course_id])
    PushCourseToSalesforce.new(@course)
    render json: { success: true }
  end

  def create_media
    set_article_course_and_user
    url = CreateSalesforceMediaRecord.new(article: @article, course: @course, user: @user,
                                          before_rev_id: params[:before_rev_id],
                                          after_rev_id: params[:after_rev_id]).url
    redirect_to url
  end

  private

  def set_article_course_and_user
    @article = Article.find(params[:article_id])
    @course = Course.find(params[:course_id])
    @user = User.find_by(username: params[:username])
  end

  # Valid Salesforce IDs are either 15 or 18 characters.
  VALID_SALESFORCE_ID_SIZES = [15, 18].freeze
  def validate_salesforce_id
    return if VALID_SALESFORCE_ID_SIZES.include? params[:salesforce_id].size
    raise InvalidSalesforceIdError
  end

  class InvalidSalesforceIdError < StandardError; end
end
