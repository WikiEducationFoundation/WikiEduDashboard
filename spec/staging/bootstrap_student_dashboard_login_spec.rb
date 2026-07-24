# frozen_string_literal: true

require_relative 'spec_helper'

# One-time interactive bootstrap for the student Chrome profile's TOP-LEVEL
# dashboard session. The screenshot harness's student happy-path shots
# (s02 enrolled course home, s03 course panel) need a first-party dashboard
# login in the student profile — the in-iframe launch's session is
# partitioned away and can't be reused top-level.
#
# A fresh profile hits Wikipedia's EmailAuth step on its first top-level
# dashboard OAuth (a one-time code Wikipedia emails the operator), which a
# headless run can't complete. Run this HEADED once and enter the code with
# "Keep me logged in" checked; that plants loginnotify_prevlogins so future
# runs stay silent, and persists the dashboard session in the profile.
#
#   CHALLENGE_WAIT=300 bin/staging-feature-spec \
#     spec/staging/bootstrap_student_dashboard_login_spec.rb
#
# (Not part of the default harvest set — it's a bootstrap utility.)
describe 'Bootstrap student dashboard login', :staging do
  let(:required_env) do
    %w[WIKIPEDIA_TEST_STUDENT_USERNAME WIKIPEDIA_TEST_STUDENT_PASSWORD]
  end

  before do
    missing = required_env.select { |k| ENV[k].to_s.empty? }
    skip("missing env vars: #{missing.join(', ')}") if missing.any?
  end

  it 'signs the student profile into the dashboard at top level' do
    in_student_browser do
      # Auto-fills the Wikipedia login form if shown; pauses at the EmailAuth
      # code step for up to CHALLENGE_WAIT seconds for the operator to enter
      # the emailed code (tick "Keep me logged in"), then confirms the
      # top-level session is established.
      ensure_dashboard_logged_in(role: :student)
      expect(page).to have_no_link('Log in', wait: 15)
      warn '  [bootstrap] student profile is now logged into the dashboard ' \
           'at top level; re-run the `student` harvest headless to capture s02/s03.'
    end
  end
end
