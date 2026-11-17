# frozen_string_literal: true
# == Schema Information
#
# Table name: article_audit_check_results
#
#  id               :bigint           not null, primary key
#  article_audit_id :bigint           not null
#  check_key        :string(255)      not null
#  check_version    :string(255)
#  engine           :string(255)
#  status           :string(255)      default("running"), not null
#  error            :text(65535)
#  findings         :text(16777215)
#  artifacts        :text(16777215)
#  usage            :text(65535)
#  duration_ms      :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

require_dependency "#{Rails.root}/lib/llm/client"

# The output of one check (see lib/article_auditing/check.rb) for one audit.
#
# - findings: Array of Hashes in the shared finding schema
#   (ArticleAuditing::Finding)
# - artifacts: Hash of check-specific structured output that isn't a finding,
#   such as a proposed short description or a table of sources
# - usage: token counts and other run metadata, eg dropped_quotes
# - engine: what produced the result, eg 'deterministic' or
#   'anthropic:claude-opus-5-5'
# - check_version: a digest of the check's prompt and code version, so that
#   results from different prompt revisions can be told apart
class ArticleAuditCheckResult < ApplicationRecord
  belongs_to :article_audit

  serialize :findings, coder: JSON
  serialize :artifacts, coder: JSON
  serialize :usage, coder: JSON

  RUNNING = 'running'
  SUCCEEDED = 'succeeded'
  FAILED = 'failed'
  STATUSES = [RUNNING, SUCCEEDED, FAILED].freeze

  validates :status, inclusion: { in: STATUSES }

  def succeeded?
    status == SUCCEEDED
  end

  def failed?
    status == FAILED
  end

  # Whether an LLM produced the result, so its findings and artifacts are AI
  # output. The engine starts with the provider, eg 'anthropic:'.
  def llm?
    Llm::Client::ADAPTERS.key?(engine.to_s.split(':').first)
  end
end
