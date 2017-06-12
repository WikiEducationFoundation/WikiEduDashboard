# frozen_string_literal: true

#= Controller for adding multiple users to a course at once
class RequestedAccountsController < ApplicationController
  respond_to :html
  before_action :set_course

  def request_account
    # check for correct passcode
    # create RequestedAccount
  end

  def index; end

  def create_accounts
    # check permissions
    @results = []
    @course.requested_accounts.each do |requested_account|
      @results << CreateRequestedAccount.new(requested_account, current_user).result
    end
  end

  private

  def set_course
    @course = Course.find_by_slug(params[:course_slug])
    pp @course
  end
end
