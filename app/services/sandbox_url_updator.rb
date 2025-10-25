# frozen_string_literal: true
class SandboxUrlUpdator
  class InvalidUrlError < StandardError; end
  class MismatchedWikiError < StandardError; end
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
    when SandboxUrlUpdator::MismatchedWikiError
      { json: { errors: e, message: e.message }, status: :unprocessable_entity }
    else
      { json: { errors: e, message: e.message }, status: :internal_server_error }
    end
  end

  private

  def process_input
    # Accept only username input
    user = find_user_by_username(@input.strip)
    @new_url = generate_sandbox_url_for_user(user)
  end

  def find_user_by_username(username)
    # Remove "User:" prefix if present
    username = username.sub(/^User:/, '') if username.start_with?('User:')

    # Find the user in the database
    user = User.find_by(username:)
    return user if user

    raise UserNotFoundError, I18n.t('assignments.invalid_username', username:)
  end

  def generate_sandbox_url_for_user(user)
    existing_url = @assignment.sandbox_url
    raise InvalidUrlError, I18n.t('assignments.invalid_url', url: @input) unless existing_url

    # Extract the article title from the existing sandbox URL
    article_title = 'sandbox'
    match = existing_url.match(%r{/wiki/User:[^/]+/(.+)})
    article_title = match[1] if match && match[1]

    # Get wiki information from existing URL
    wiki_match = existing_url.match(%r{https://([^.]*)\.([^.]*)\.org})
    raise InvalidUrlError, I18n.t('assignments.invalid_url', url: existing_url) unless wiki_match

    existing_language, existing_project = wiki_match.captures

    # Generate new URL with the user's username
    base_url = "https://#{existing_language}.#{existing_project}.org/wiki"
    "#{base_url}/User:#{user.username}/#{article_title}"
  end

  def validate_new_url
    existing_url = @assignment.sandbox_url
    raise InvalidUrlError, I18n.t('assignments.invalid_url', url: @new_url) unless existing_url

    wiki_match = existing_url.match(%r{https://([^.]*)\.([^.]*)\.org})
    raise InvalidUrlError, I18n.t('assignments.invalid_url', url: existing_url) unless wiki_match

    existing_language, existing_project = wiki_match.captures
    new_url_match = @new_url.match(%r{^https://([^./]++)\.([^./]++)\.org/wiki/User:([^/#<>\[\]|{}:.]+)/([^/#<>\[\]|{}:.]+)})

    # Handle invalid url
    raise InvalidUrlError, I18n.t('assignments.invalid_url', url: @new_url) unless new_url_match
    # Handle mismatched wiki
    new_language, new_project = new_url_match.captures
    wiki_matches = (existing_language == new_language && existing_project == new_project)
    handle_mismatched_wiki unless wiki_matches
  end

  def handle_mismatched_wiki
    raise MismatchedWikiError, I18n.t('assignments.mismatched_wiki', url: @new_url)
  end
end
