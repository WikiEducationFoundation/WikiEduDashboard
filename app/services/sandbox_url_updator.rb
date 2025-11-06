# frozen_string_literal: true
class SandboxUrlUpdator
  class InvalidUrlError < StandardError; end
  class UserNotFoundError < StandardError; end

  def initialize(new_url = nil, assignment = nil)
    @input = new_url
    @assignment = assignment
    @new_url = nil
  end

  def update
    process_input
    validate_new_url
    @assignment.update_sandbox_url(@new_url)
    return { partial: 'updated_assignment', locals: { assignment: @assignment } }
  rescue StandardError => e
    case e
    when SandboxUrlUpdator::InvalidUrlError, SandboxUrlUpdator::UserNotFoundError
      { json: { errors: e, message: e.message }, status: :bad_request }
    else
      { json: { errors: e, message: e.message }, status: :internal_server_error }
    end
  end

  private

  def process_input
    # Accept only username input
    user = find_user_by_username(@input.strip)
    @new_url = @assignment.default_sandbox_url(user.username)
  end

  def find_user_by_username(username)
    # Remove "User:" prefix if present
    username = username.sub(/^User:/, '') if username.start_with?('User:')

    # Find the user in the database
    user = User.find_by(username:)
    return user if user

    raise UserNotFoundError, I18n.t('assignments.invalid_username', username:)
  end

  def validate_new_url
    # Basic validation - ensure the URL was generated successfully
    raise InvalidUrlError, I18n.t('assignments.invalid_url', url: @new_url) unless @new_url

    # Ensure the new URL matches the expected pattern for a sandbox URL
    new_url_match = @new_url.match(%r{^https://([^./]++)\.([^./]++)\.org/wiki/User:([^/#<>\[\]|{}:.]+)/([^/#<>\[\]|{}:.]+)})
    raise InvalidUrlError, I18n.t('assignments.invalid_url', url: @new_url) unless new_url_match
  end
end
