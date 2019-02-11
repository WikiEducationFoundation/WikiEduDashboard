# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/wiki_edits"
require_dependency "#{Rails.root}/lib/importers/user_importer"

# Processes a RequestedAccount by creating a new mediawiki account, and
# creating the User record upon success.
class CreateRequestedAccount
  attr_reader :result, :user, :creator

  def initialize(requested_account, creator)
    @creator = creator
    @requested_account = requested_account
    @course = requested_account.course
    # FIXME: Temporary workaround for A+F 2018, where organizers have account creator
    # rights on en.wiki, no matter what the home wiki of the project.
    @wiki = Wiki.find_by(language: 'en', project: 'wikipedia')
    @username = requested_account.username
    @email = requested_account.email.strip
    # This instance variable is used to determine whether or not to retry
    # the account creation with a backup account
    @use_backup_creator = false

    course_link = "#{ENV['dashboard_url']}/courses/#{@course.slug}"
    @creation_reason = I18n.t('wiki_api.create_account_reason', event: course_link)
    process_request(@creator, @creation_reason)
  end

  private

  def process_request(creator, creation_reason)
    @wiki_edits ||= WikiEdits.new(@wiki)
    @response = @wiki_edits.create_account(creator: creator,
                                           username: @username,
                                           email: @email,
                                           reason: creation_reason)
    handle_mediawiki_response
  end

  # We only handle one-step PASS and FAIL statuses. For more complicated results,
  # such as an intermediate CAPTCHA step, we just fail immediately; users are expected
  # to have account creator rights on the target wiki, so that CAPTCHA is not required.
  def handle_mediawiki_response
    response = @response['createaccount'] || {}
    status, message, messagecode = response.values_at('status',
                                                      'message',
                                                      'messagecode')

    status == 'PASS' ? create_account : handle_failed_account_creation(message, messagecode)
  end

  def create_account
    @result = { success: "Created account for #{@username} on #{@wiki.base_url}.
                            A password will be emailed to #{@email}." }

    returned_username = @response.dig('createaccount', 'username')
    raise AccountCreationError, 'no username returned' if returned_username.blank?
    @user = UserImporter.new_from_username(returned_username, @wiki)
    raise AccountCreationError, "could not create user #{returned_username}" if @user.blank?

    @requested_account.destroy
  end

  MESSAGE_CODES_TO_RETRY = [
    'acct_creation_throttle_hit',
    'captcha-createaccount-fail'
  ].freeze
  def handle_failed_account_creation(message, messagecode)
    if messagecode == 'userexists'
      destroy_request_if_user_exists(message, messagecode)
    elsif MESSAGE_CODES_TO_RETRY.include?(messagecode) && !@use_backup_creator
      retry_request_with_backup_account
    else
      log_unexpected_response
    end
  end

  def destroy_request_if_user_exists(message, messagecode)
    @result = { failure: "Could not create account for #{@username} / #{@email}.
                            #{@wiki.base_url} message:
                            #{messagecode} — #{message}" }

    code = @response.dig('createaccount', 'messagecode')
    @requested_account.destroy if code == 'userexists'
  end

  def retry_request_with_backup_account
    @use_backup_creator = true
    backup_account = SpecialUsers.backup_account_creator

    creation_reason = "#{@creation_reason} Account created by #{@creator.username}."
    process_request(backup_account, creation_reason)
  end

  def log_unexpected_response
    @result = { failure: "Could not create account for #{@username} /
                      #{@email}. #{@wiki.base_url} response: #{@response}" }

    raise AccountCreationError, 'unexpected account creation response'
  rescue AccountCreationError => e
    Raven.capture_exception(e, extra: { response: @response })
  end

  class AccountCreationError < StandardError; end
end
