# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/wiki_edits"

# Installs an opt-in experiment's userscript on a student's English Wikipedia
# account by prepending an import line to their User:<name>/common.js, using
# the student's own OAuth credentials.
#
# A missing-grant/permission failure (the token is valid but lacks the
# "Edit your user CSS/JSON/JavaScript" grant) is reported as :reauth_required
# so the caller can prompt the student to re-authorize, rather than treating
# the token as invalid and logging them out.
class InstallExperimentUserscript
  attr_reader :status

  def initialize(experiment_courses_user, experiment)
    @record = experiment_courses_user
    @experiment = experiment
    @user = experiment_courses_user.user
    @status = install
  end

  private

  # MediaWiki error codes that mean the OAuth token is under-scoped for this
  # edit (a missing grant) and the student should re-authorize, rather than the
  # token being treated as invalid. The production case is CONFIRMED: a consumer
  # with read+edit but lacking `editmyuserjs` returns `mycustomjsprotected`
  # ("You do not have permission to edit this JavaScript page.") when editing the
  # user's own JS. The rest are defense-in-depth for a more broadly under-scoped
  # token: `readapidenied`/`writeapidenied` (no read/edit grant), `customjsprotected`
  # (someone else's JS), and a generic `permissiondenied`.
  PERMISSION_ERROR_CODES = %w[mycustomjsprotected customjsprotected permissiondenied
                              readapidenied writeapidenied].freeze

  def install
    return :disabled if Features.disable_wiki_output?

    response = post_userscript
    return record_success if edit_succeeded?(response)
    return :reauth_required if missing_grant?(response)

    record_error(response)
    :error
  end

  def post_userscript
    en_wiki = Wiki.get_or_create(language: 'en', project: 'wikipedia')
    WikiEdits.new(en_wiki).add_to_page_top(
      "User:#{@user.username}/common.js", @user,
      "#{@experiment.userscript_import_line}\n", @experiment.edit_summary
    )
  end

  def edit_succeeded?(response)
    response.dig('edit', 'result') == 'Success'
  end

  def missing_grant?(response)
    PERMISSION_ERROR_CODES.include?(response.dig('error', 'code'))
  end

  def record_success
    @record.update!(userscript_installed_at: Time.zone.now)
    :installed
  end

  def record_error(response)
    Sentry.capture_message('InstallExperimentUserscript failed',
                           level: 'warning',
                           extra: { username: @user.username,
                                    experiment: @experiment.slug,
                                    response: })
  end
end
