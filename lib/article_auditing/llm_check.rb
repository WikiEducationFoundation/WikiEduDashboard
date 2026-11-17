# frozen_string_literal: true

require 'digest'
require_dependency "#{Rails.root}/lib/article_auditing/check"
require_dependency "#{Rails.root}/lib/article_auditing/quote_validator"
require_dependency "#{Rails.root}/lib/article_auditing/llm_output_schema"
require_dependency "#{Rails.root}/lib/llm/client"

module ArticleAuditing
  # A check whose judgment comes from an LLM prompt. The prompt lives in
  # config/article_audit/prompts/<KEY>.md so it can be edited without code
  # changes. #version digests that prompt together with the shared system
  # prompt (_system.md) and the schema, so results from different prompt
  # revisions can be told apart.
  #
  # The provider, model and effort come from the check's entry in
  # config/article_audit_checks.yml.
  #
  # Subclasses set KEY and CATEGORY. A check that returns an artifact names
  # its property of LlmOutputSchema in ARTIFACTS.
  class LlmCheck < Check
    ARTIFACTS = [].freeze
    PROMPT_DIR = Rails.root.join('config/article_audit/prompts')
    SYSTEM_PROMPT_PATH = PROMPT_DIR.join('_system.md')

    # Instructions shared by every LLM check; see Context#llm_system_blocks.
    def self.system_prompt
      File.read(SYSTEM_PROMPT_PATH)
    end

    def engine
      "#{provider}:#{model}"
    end

    # Whether the check's requests start with the article's cached system
    # blocks (see RunArticleAudit). Checks that send other content say no.
    def shares_article_cache?
      true
    end

    def version
      inputs = [self.class.system_prompt, prompt, schema.to_json, self.class::VERSION]
      digest = Digest::SHA256.hexdigest(inputs.join("\n"))
      digest.first(12)
    end

    def run(context)
      response = adapter.complete(system_blocks: context.llm_system_blocks,
                                  user: user_content(context), json_schema: schema, model:, effort:)
      json = response.json || {}
      findings = build_findings(json['findings'])
      unverified = QuoteValidator.new(context).mark!(findings)
      output(findings, artifacts: artifacts_from(json),
                       usage: response.usage.merge('model' => response.model,
                                                   'unverified_quotes' => unverified))
    end

    def prompt
      @prompt ||= File.read(PROMPT_DIR.join("#{key}.md"))
    end

    # Shared by every check, so that they all read the same prompt cache.
    def schema
      LlmOutputSchema::SCHEMA
    end

    private

    # The request's user message: the check's prompt, plus any data the check
    # gathered about the wiki (see checks that override this). The article
    # itself is in the cached system blocks.
    def user_content(_context)
      prompt
    end

    def provider
      config.fetch('provider', 'anthropic')
    end

    def model
      config['model'] || Llm::AnthropicAdapter::DEFAULT_MODEL
    end

    def effort
      config['effort']
    end

    def adapter
      Llm::Client.adapter(provider)
    end

    # This check's own artifacts, ignoring any the model filled for others.
    def artifacts_from(json)
      json.slice(*self.class::ARTIFACTS)
    end

    def build_findings(raw_findings)
      Array(raw_findings).map do |raw|
        finding(**raw.slice(*%w[severity title explanation section quote suggestion policy_refs])
                     .symbolize_keys)
      end
    end
  end
end
