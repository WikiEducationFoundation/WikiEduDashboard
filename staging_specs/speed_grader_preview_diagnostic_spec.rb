# frozen_string_literal: true

require_relative 'spec_helper'

# Diagnostic: what does SpeedGrader actually load for a column whose grade
# arrived over AGS?
#
# The operator reports that some columns show a student-specific view there and
# others show the roster. Every column's latest attempt stores a per-student
# launch URL (checked over the REST API), so the question is which of those URLs
# — if any — SpeedGrader iframes. The Canvas REST API can't answer it: the
# preview page is HTML behind a session, and an access token gets a 302.
#
# So drive SpeedGrader with a real instructor session and report, per column, the
# iframe sources on the page and the first text inside the tool frame. Reports
# rather than asserts: this exists to tell us where the gap is, and a wrong guess
# baked into an expectation would just hide it.
describe 'SpeedGrader preview diagnostic', :staging do
  let(:required_env) do
    %w[CANVAS_TEST_INSTRUCTOR_LOGIN CANVAS_TEST_INSTRUCTOR_PASSWORD
       CANVAS_TEST_STUDENT_USER_ID]
  end

  # The operator's walkthrough course: one graded mechanical column, one
  # graded fractional column, and three instructor-graded ones (pending_review).
  let(:course_id) { 292 }
  let(:columns) do
    { 626 => 'Wikipedia account (graded)',
      627 => 'Wikipedia trainings (graded, fractional)',
      628 => 'Wk2 Fact verification (pending_review)',
      632 => 'Wk4 Bibliography (pending_review)',
      633 => 'Wikipedia peer review (pending_review)' }
  end

  before do
    missing = required_env.reject { |key| ENV[key].present? rescue ENV[key].to_s != '' }
    skip("missing env: #{missing.join(', ')}") if missing.any?
  end

  it 'reports what each column loads in SpeedGrader' do
    student_id = ENV.fetch('CANVAS_TEST_STUDENT_USER_ID')
    in_canvas do
      ensure_canvas_logged_in_as_instructor
      columns.each do |assignment_id, label|
        visit "https://canvas.wikiedu.org/courses/#{course_id}/gradebook/" \
              "speed_grader?assignment_id=#{assignment_id}&student_id=#{student_id}"
        sleep 8
        report(label, assignment_id)
      end
    end
  end

  def report(label, assignment_id)
    warn "\n== #{label} [#{assignment_id}]"
    frames = all('iframe', visible: :all, wait: 10)
    warn "   iframes: #{frames.size}"
    frames.each_with_index do |frame, i|
      src = frame[:src].to_s
      warn "     [#{i}] id=#{frame[:id].inspect} class=#{frame[:class].inspect}"
      warn "         src=#{src[0, 220]}"
      warn "         MARKER=#{marker_in(src).inspect}"
    end
    tool = frames.find { |f| f[:src].to_s.include?('external_tools') || f[:id] == 'tool_content' }
    warn '   no tool iframe found' and return if tool.nil?

    text = within_frame(tool) { page.text.to_s[0, 320] } rescue "unreadable: #{$ERROR_INFO&.class}"
    warn "   tool frame text: #{text.gsub(/\s+/, ' ')}"
  end

  # The `submission` marker is what makes a launch student-specific; Canvas
  # wraps our URL (encoded) inside external_tools/retrieve.
  def marker_in(src)
    decoded = CGI.unescape(CGI.unescape(src))
    decoded[/submission=([^&\s]+)/, 1]
  end
end
