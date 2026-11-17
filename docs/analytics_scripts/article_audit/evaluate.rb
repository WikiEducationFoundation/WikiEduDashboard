# frozen_string_literal: true

# Runs Article Audits over a list of pages, or collects audits that have
# already run, and exports them for the team to review by hand. See README.md.
#
#   URLS=~/audit_urls.txt bundle exec rails runner docs/analytics_scripts/article_audit/evaluate.rb
#   AUDIT_IDS=5,7,10 bundle exec rails runner docs/analytics_scripts/article_audit/evaluate.rb
#
# Optional: CHECKS=tone,policy runs only those checks; OUT=dir chooses where
# the files go (default ~/article_audit_eval/<timestamp>).

require 'csv'
require 'json'
require 'fileutils'
require Rails.root.join('app/services/run_article_audit').to_s

module ArticleAuditEvaluation
  # US dollars per million tokens, by model, as of November 2026.
  PRICES = {
    'claude-opus-5-5' => { 'input_tokens' => 4.0, 'output_tokens' => 20.0,
                           'cache_creation_input_tokens' => 5.0,
                           'cache_read_input_tokens' => 0.2 }
  }.freeze

  FINDING_COLUMNS = %w[
    audit_id article revision_url check category engine severity title code details explanation
    section quote quote_verified suggestion policy_refs accurate useful reviewer_notes
  ].freeze

  CHECK_COLUMNS = %w[
    audit_id article check engine version status findings input_tokens output_tokens
    cache_creation_input_tokens cache_read_input_tokens cost_usd duration_ms error
  ].freeze

  module_function

  def run
    audits = ENV['URLS'] ? run_audits(urls) : existing_audits
    abort 'Nothing to export: set URLS or AUDIT_IDS.' if audits.empty?
    write(audits)
  end

  def urls
    File.readlines(File.expand_path(ENV['URLS'])).map(&:strip).reject do |line|
      line.empty? || line.start_with?('#')
    end
  end

  def existing_audits
    ids = ENV['AUDIT_IDS'].to_s.split(',').map(&:strip)
    ArticleAudit.where(id: ids).includes(:check_results, :wiki).order(:id).to_a
  end

  # One audit at a time, in this process, so the wiki is fetched politely and
  # nothing is queued for Sidekiq to run a second time.
  def run_audits(list)
    list.filter_map do |url|
      creator = CreateArticleAudit.new(url:, requester: nil, enqueue: false)
      next warn("#{url}: #{creator.error}") if creator.audit.nil?
      RunArticleAudit.new(creator.audit, checks:)
      audit = creator.audit.reload
      puts format('%-6s %-9s $%.2f  %s', audit.id, audit.status, audit_cost(audit), url)
      audit
    end
  end

  def checks
    keys = ENV['CHECKS'].to_s.split(',').map(&:strip)
    return ArticleAuditing::Registry.enabled_checks if keys.empty?
    keys.map { |key| ArticleAuditing::Registry.check(key) }
  end

  def cost(result)
    model = result.usage&.dig('model')
    prices = PRICES[model]
    return if prices.nil?
    prices.sum { |key, price| result.usage[key].to_i * price / 1_000_000 }.round(4)
  end

  def audit_cost(audit)
    audit.latest_check_results.sum { |result| cost(result) || 0 }
  end

  def write(audits)
    default = "~/article_audit_eval/#{Time.zone.now.strftime('%F-%H%M')}"
    dir = File.expand_path(ENV['OUT'] || default)
    FileUtils.mkdir_p(dir)
    File.write(File.join(dir, 'audits.json'),
               JSON.pretty_generate(audits.map { |a| audit_json(a) }))
    write_csv(File.join(dir, 'findings.csv'), FINDING_COLUMNS,
              audits.flat_map { |a| finding_rows(a) })
    write_csv(File.join(dir, 'checks.csv'), CHECK_COLUMNS, audits.flat_map { |a| check_rows(a) })
    total = audits.sum { |audit| audit_cost(audit) }
    puts format('%<count>d audits, $%<total>.2f, written to %<dir>s',
                count: audits.size, total:, dir:)
  end

  def write_csv(path, columns, rows)
    CSV.open(path, 'w') do |csv|
      csv << columns
      rows.each { |row| csv << row.values_at(*columns) }
    end
  end

  def audit_json(audit)
    audit.as_json(only: %i[id url article_title mw_rev_id namespace status error started_at
                           completed_at])
         .merge('revision_url' => audit.revision_url, 'cost_usd' => audit_cost(audit).round(4),
                'checks' => audit.latest_check_results.map { |result| result_json(result) })
  end

  def result_json(result)
    result.as_json(only: %i[check_key check_version engine status error duration_ms findings
                            artifacts usage])
          .merge('cost_usd' => cost(result))
  end

  def finding_rows(audit)
    audit.latest_check_results.flat_map do |result|
      Array(result.findings).map { |finding| finding_row(audit, result, finding) }
    end
  end

  def finding_row(audit, result, finding)
    location = finding['location'] || {}
    finding.slice(*%w[check category severity title code explanation suggestion])
           .merge('audit_id' => audit.id, 'article' => audit.article_title,
                  'revision_url' => audit.revision_url, 'engine' => result.engine,
                  'details' => finding['details']&.to_json, 'section' => location['section'],
                  'quote' => location['quote'], 'quote_verified' => location['quote_verified'],
                  'policy_refs' => Array(finding['policy_refs']).join(' '))
  end

  def check_rows(audit)
    audit.latest_check_results.map do |result|
      (result.usage || {}).slice(*CHECK_COLUMNS)
                          .merge('audit_id' => audit.id, 'article' => audit.article_title,
                                 'check' => result.check_key, 'engine' => result.engine,
                                 'version' => result.check_version, 'status' => result.status,
                                 'findings' => Array(result.findings).size,
                                 'cost_usd' => cost(result), 'duration_ms' => result.duration_ms,
                                 'error' => result.error)
    end
  end
end

ArticleAuditEvaluation.run
