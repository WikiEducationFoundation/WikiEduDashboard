# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/wiki_api"

# Inspects a student's English Wikipedia common.js to see whether an opt-in
# experiment's userscript is present, and records the install timestamp the
# first time it is found.
#
# This is an unauthenticated read, so it needs no OAuth grant. Students install
# the userscript themselves by pasting the import line into their common.js; the
# Dashboard confirms it after the fact rather than making the edit on their
# behalf. A wiki that cannot be read simply reports :not_installed, which leaves
# the install step showing — the safe direction to fail in.
class CheckExperimentUserscript
  attr_reader :status

  def initialize(experiment_courses_user, experiment)
    @record = experiment_courses_user
    @experiment = experiment
    @user = experiment_courses_user.user
    @status = derive_status
  end

  private

  def fetch_common_js
    en_wiki = Wiki.get_or_create(language: 'en', project: 'wikipedia')
    WikiApi.new(en_wiki).get_page_content(@experiment.userscript_target_page(@user))
  rescue StandardError => e
    Sentry.capture_exception(e, level: 'warning',
                                extra: { username: @user.username,
                                         experiment: @experiment.slug })
    nil
  end

  def derive_status
    return :not_installed unless installed?

    record_install
    :installed
  end

  # Matched on the imported script's page title rather than the whole import
  # line, so a student who retypes it with different quoting or spacing still
  # counts as installed.
  def installed?
    fetch_common_js&.include?(@experiment.userscript_marker) || false
  end

  def record_install
    return if @record.userscript_installed_at

    @record.update!(userscript_installed_at: Time.zone.now)
  end
end
