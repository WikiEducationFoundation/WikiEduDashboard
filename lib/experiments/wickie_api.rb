# frozen_string_literal: true

# Client for the Fall 2026 research experiment's data collection server
# ("wickie", source: https://github.com/humans-and-machines/wikiedu-intervention).
# Experiment-specific; delete along with Fall2026ResearchExperiment when the
# study ends.
class WickieApi
  ENROLL_URL = 'https://wickie.ink/enroll'

  class EnrollmentFailed < StandardError; end

  # Announces a student's opt-in so the server accepts data from their
  # userscript. The endpoint is idempotent, so Sidekiq retries are safe.
  #
  # Without a configured secret this makes no request at all, so opt-ins on an
  # environment that isn't meant to feed the study (development, test, a
  # staging box) can never land in the real cohort.
  def enroll(username:, course_slug:)
    return if secret.blank?

    response = post_enrollment(username:, course_slug:)
    return if response.success?

    # 5xx and network errors raise so Sidekiq retries them; a 4xx (malformed
    # request, wrong secret) cannot succeed on retry, so it only alerts.
    raise EnrollmentFailed, "#{response.status}: #{response.body}" if response.status >= 500

    Sentry.capture_message('wickie enrollment rejected',
                           level: 'error',
                           extra: { status: response.status, body: response.body,
                                    username:, course: course_slug })
  end

  private

  def secret
    ENV['wickie_enroll_secret']
  end

  def post_enrollment(username:, course_slug:)
    conn = Faraday.new(url: ENROLL_URL,
                       headers: { 'Content-Type' => 'application/json' })
    conn.headers['User-Agent'] = ENV['dashboard_url'] + ' ' + Rails.env
    conn.post('') do |req|
      req.body = { secret:, username:, course: course_slug }.to_json
    end
  end
end
