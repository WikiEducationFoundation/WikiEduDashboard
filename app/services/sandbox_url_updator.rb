# frozen_string_literal: true
class SandboxUrlUpdator
  class InvalidUrlError < StandardError; end
  class MismatchedWikiError < StandardError; end

  def initialize(new_url = nil, assignment = nil)
    @new_url = new_url
    @assignment = assignment
  end

  def update
    validate_new_url
    @assignment.update_sandbox_url(@new_url)
    return { partial: 'updated_assignment', locals: { assignment: @assignment } }
  rescue StandardError => e
    case e
    when SandboxUrlUpdator::InvalidUrlError
      { json: { errors: e, message: e.message }, status: :bad_request }
    when SandboxUrlUpdator::MismatchedWikiError
      { json: { errors: e, message: e.message }, status: :unprocessable_entity }
    else
      { json: { errors: e, message: e.message }, status: :internal_server_error }
    end
  end

  def validate_new_url
    existing_url = @assignment.sandbox_url
    existing_language, existing_project = existing_url.match(%r{https://([^.]*)\.([^.]*)\.org}).captures
    new_url_match = @new_url.match(%r{^https://([^./]++)\.([^./]++)\.org/wiki/User:([^/#<>\[\]|{}:.]+)/([^/#<>\[\]|{}:.]+)})

    # Handle invalid url
    raise InvalidUrlError, I18n.t('assignments.invalid_url', url: @new_url) unless new_url_match
    # Handle mismatched wiki
    new_language, new_project = new_url_match.captures
    unless existing_language == new_language && existing_project == new_project
      raise MismatchedWikiError, I18n.t('assignments.mismatched_wiki', url: @new_url)
    end
  end
end
