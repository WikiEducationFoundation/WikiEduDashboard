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
    @wiki = @course.home_wiki.edits_enabled? ? @course.home_wiki : en_wiki

    @username = requested_account.username
    @email = requested_account.email.strip
    # This instance variable is used to determine whether or not to retry
    # the account creation with a backup account and/or en.wiki
    @use_backup_creator = false

    course_link = "#{ENV['dashboard_url']}/courses/#{@course.slug}"
    @creation_reason = I18n.t('wiki_api.create_account_reason', event: course_link,
                                                                locale: @wiki.language)
    process_request(@creator, @creation_reason)
  end

  def set_result_description
    if @result[:failure]
      @result[:result_description] = I18n.t('users.requested_account_status.failure_message',
                                            result_description: @result[:failure])
    elsif @result[:success]
      @result[:result_description] = I18n.t('users.requested_account_status.success_message',
                                            result_description: @result[:success])
    end
  end

  private

  def en_wiki
    @en_wiki ||= Wiki.find_by(language: 'en', project: 'wikipedia')
  end

  def process_request(creator, creation_reason)
    @wiki_edits = WikiEdits.new(@wiki)
    @response = @wiki_edits.create_account(creator:,
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
    set_result_description
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

  MESSAGE_CODES_TO_RETRY = %w[
    acct_creation_throttle_hit
    captcha-createaccount-fail
  ].freeze
  def handle_failed_account_creation(message, messagecode)
    if messagecode == 'userexists'
      destroy_request_if_user_exists
    elsif MESSAGE_CODES_TO_RETRY.include?(messagecode) && !@use_backup_creator
      retry_request_with_backup_account_on_en_wiki
    else
      report_failure(message, messagecode)
    end
  end

  def destroy_request_if_user_exists
    enrolled = enrolled_user_with_requested_username
    details = { code: 'userexists' }
    details[:existing_username] = enrolled.username if enrolled
    reason = enrolled ? :user_exists_enrolled : :user_exists
    @result = { failure: failure_message(reason, **details) }
    @requested_account.destroy
  end

  # MediaWiki capitalizes the first letter and treats underscores as spaces; the
  # username column's collation already ignores case.
  def enrolled_user_with_requested_username
    @course.users.find_by(username: @username.tr('_', ' ').squish)
  end

  def retry_request_with_backup_account_on_en_wiki
    @use_backup_creator = true
    @wiki = en_wiki

    backup_account = SpecialUsers.backup_account_creator

    creation_reason = "#{@creation_reason} Account created by #{@creator.username}."
    process_request(backup_account, creation_reason)
  end

  FAILURE_REASONS = {
    'acct_creation_throttle_hit' => :throttled,
    'captcha-createaccount-fail' => :captcha_required
  }.freeze

  # The facilitator gets a readable explanation that keeps the code identifying the
  # problem. The raw response goes to Sentry, and to the facilitator only when the
  # response matches none of the known shapes.
  def report_failure(message, messagecode)
    reason, details = failure_reason(message, messagecode)
    @result = { failure: failure_message(reason, **details) }

    code = details[:code] || 'unexpected response'
    Sentry.capture_exception(AccountCreationError.new("account creation failed: #{code}"),
                             extra: { response: @response })
  end

  def failure_reason(message, messagecode)
    if messagecode
      details = { code: messagecode, message: message.presence || messagecode }
      enrolled = messagecode == 'antispoof-conflict' && enrolled_user_with_requested_username
      if enrolled
        [:name_conflict_enrolled, details.merge(existing_username: enrolled.username)]
      else
        [FAILURE_REASONS[messagecode] || :rejected, details]
      end
    elsif (error = api_error)
      [:api_error, { code: error['code'], message: error['info'] }]
    else
      [:unexpected, { response: @response.to_s }]
    end
  end

  # A failed token request reports its error under a symbol key; an error from the
  # createaccount request itself comes back from the API under a string key.
  def api_error
    error = @response[:error] || @response['error']
    error if error.is_a?(Hash) && error['code'].present?
  end

  def failure_message(reason, **details)
    I18n.t("users.requested_account_status.#{reason}",
           username: @username, email: @email, wiki: @wiki.domain, **details)
  end

  class AccountCreationError < StandardError; end
end
