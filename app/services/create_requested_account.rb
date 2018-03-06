# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/wiki_edits"
require_dependency "#{Rails.root}/lib/importers/user_importer"

# Processes a RequestedAccount by creating a new mediawiki account, and
# creating the User record upon success.
class CreateRequestedAccount
  attr_reader :result, :user

  def initialize(requested_account, creator)
    @creator = creator
    @requested_account = requested_account
    @course = requested_account.course
    # FIXME: Temporary workaround for A+F 2018, where organizers have account creator
    # rights on en.wiki, no matter what the home wiki of the project.
    @wiki = Wiki.find_by(language: 'en', project: 'wikipedia')
    @username = requested_account.username
    @email = requested_account.email.strip
    process_request
  end

  private

  def process_request
    course_link = "#{ENV['dashboard_url']}/courses/#{@course.slug}"
    creation_reason = I18n.t('wiki_api.create_account_reason', event: course_link)
    @response = WikiEdits.new(@wiki).create_account(creator: @creator,
                                                    username: @username,
                                                    email: @email,
                                                    reason: creation_reason)
    handle_mediawiki_response
  end

  # We only handle one-step PASS and FAIL statuses. For more complicated results,
  # such as an intermediate CAPTCHA step, we just fail immediately; users are expected
  # to have account creator rights on the target wiki, so that CAPTCHA is not required.
  def handle_mediawiki_response
    response_status = @response.dig('createaccount', 'status')
    if response_status == 'PASS'
      @result = { success: "Created account for #{@username} on #{@wiki.base_url}.
                            A password will be emailed to #{@email}." }
      create_account
      @requested_account.destroy
    elsif response_status == 'FAIL'
      @result = { failure: "Could not create account for #{@username} / #{@email}.
                            #{@wiki.base_url} message:
                            #{@response.dig('createaccount', 'messagecode')}
                            — #{@response.dig('createaccount', 'message')}" }
      destroy_request_if_invalid
    else
      @result = { failure: "Could not create account for #{@username} /
                            #{@email}. #{@wiki.base_url} response: #{@response}" }
      log_unexpected_response
    end
  end

  def create_account
    returned_username = @response.dig('createaccount', 'username')
    raise AccountCreationError, 'no username returned' if returned_username.blank?
    @user = UserImporter.new_from_username(returned_username, @wiki)
    raise AccountCreationError, "could not create user #{returned_username}" if @user.blank?
  end

  def destroy_request_if_invalid
    code = @response.dig('createaccount', 'messagecode')
    @requested_account.destroy if code == 'userexists'
  end

  def log_unexpected_response
    raise AccountCreationError, 'unexpected account creation response'
  rescue AccountCreationError => e
    Raven.capture_exception(e, extra: { response: @response })
  end

  class AccountCreationError < StandardError; end
end
