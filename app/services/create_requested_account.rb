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

    course_link = "#{ENV['dashboard_url']}/courses/#{@course.slug}"
    creation_reason = I18n.t('wiki_api.create_account_reason', event: course_link)
    process_request(@creator, creation_reason)
  end

  private

  def process_request(creator, creation_reason)
    @response = WikiEdits.new(@wiki).create_account(creator: creator,
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

    if status == 'PASS'
      create_account
    elsif status == 'FAIL' && messagecode == 'userexists'
      destroy_request_if_user_exists(message, messagecode)
    else
      retry_request_with_backup_account
    end
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

  def destroy_request_if_user_exists(message, messagecode)
    @result = { failure: "Could not create account for #{@username} / #{@email}.
                            #{@wiki.base_url} message:
                            #{messagecode} — #{message}" }

    code = @response.dig('createaccount', 'messagecode')
    @requested_account.destroy if code == 'userexists'
  end

  def retry_request_with_backup_account
    backup_account_id = ENV['account_creation_backup_creator_id']
    backup_account = User.find_by(id: backup_account_id)
    return log_unexpected_response if !backup_account.is_a?(User) || backup_account == @creator

    @creator = backup_account
    creation_reason = "Created #{@username} at the request of #{@creator}."
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
