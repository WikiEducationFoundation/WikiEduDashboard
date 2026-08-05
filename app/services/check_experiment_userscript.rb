# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/wiki_api"

# Inspects a student's English Wikipedia common.js to see whether an opt-in
# experiment's userscript is present, and records the install timestamp the
# first time it is found.
#
# This is an unauthenticated read, so it needs no OAuth grant. Students install
# the userscript themselves through a preloaded edit; the Dashboard confirms it
# after the fact rather than making the edit on their behalf.
#
# `page_state` reports the shape of the student's common.js, which decides how
# the install step is presented:
#   :blank   - the page does not exist yet, so a preloaded edit will fill it in
#   :exists  - the page already has content; MediaWiki ignores `preload` on a
#              non-empty page, so the student must paste the import line in
#   :unknown - the wiki could not be read; fall back to the manual instructions,
#              which work either way
class CheckExperimentUserscript
  attr_reader :status, :page_state

  def initialize(experiment_courses_user, experiment)
    @record = experiment_courses_user
    @experiment = experiment
    @user = experiment_courses_user.user
    @content = fetch_common_js
    @page_state = derive_page_state
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

  def derive_page_state
    return :unknown if @content.nil?

    @content.strip.empty? ? :blank : :exists
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
    @content&.include?(@experiment.userscript_marker) || false
  end

  def record_install
    return if @record.userscript_installed_at

    @record.update!(userscript_installed_at: Time.zone.now)
  end
end
