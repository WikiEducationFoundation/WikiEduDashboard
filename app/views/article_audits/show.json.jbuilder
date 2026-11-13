# frozen_string_literal: true

json.audit do
  json.partial! 'article_audits/audit', audit: @audit
  json.usage @audit.usage
end
json.check_results @check_results do |result|
  json.call(result, :id, :check_key, :check_version, :engine, :status, :error, :duration_ms,
            :created_at)
  json.findings result.findings || []
  json.artifacts result.artifacts || {}
  json.usage result.usage || {}
  json.run_count @run_counts[result.check_key]
end
