# frozen_string_literal: true

# Processes a RequestedAccount by creating a new mediawiki account, and
# creating the User record upon success.
class CreateRequestedAccount
  attr_reader :result

  def initialize(requested_account, creator)
    @creator = creator
    @request_account = requested_account
    @course = requested_account.course
    @username = requested_account.username
    @email = requested_account.email
    process_request
  end

  private

  def process_request
    # try to create account
    # if successful, create User record and set @result
  end
end
