# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/article_auditing/finding"

module ArticleAuditing
  # One independent unit of an Article Audit. Each check:
  # - declares a stable KEY (also its config key in config/article_audit_checks.yml)
  #   and a CATEGORY from Finding::CATEGORIES
  # - decides whether it applies to a given revision (#applies_to?)
  # - returns findings in the shared Finding shape, plus optional artifacts
  #
  # Checks don't know about persistence or each other, so any one of them can
  # be reimplemented with a different engine — plain code, Claude, or an
  # open-weight model — without touching the rest.
  class Check
    Output = Data.define(:findings, :artifacts, :usage)

    # Bump when a check's code changes in a way that changes its output.
    VERSION = '1'

    attr_reader :config

    def initialize(config = {})
      @config = config.to_h.stringify_keys
    end

    def key
      self.class::KEY
    end

    def category
      self.class::CATEGORY
    end

    def engine
      'deterministic'
    end

    def version
      self.class::VERSION
    end

    def applies_to?(_context)
      true
    end

    # Returns an Output.
    def run(_context)
      raise NotImplementedError
    end

    private

    def finding(**attrs)
      Finding.build(check: key, category:, **attrs)
    end

    # The code and details for one of this check's finding types. A
    # finding from code names the problem with a code rather than prose, so
    # there is no copy to write; the policy links explain it.
    def coded(code, **details)
      { code:, details: }
    end

    def output(findings, artifacts: {}, usage: {})
      Output.new(findings:, artifacts:, usage:)
    end

    # A short excerpt of +text+ around +index+, on a single line, for use as
    # a finding's quote.
    def excerpt(text, index, length: 60)
      start = [index - (length / 2), 0].max
      text[start, length].to_s.tr("\n", ' ').strip
    end
  end
end
