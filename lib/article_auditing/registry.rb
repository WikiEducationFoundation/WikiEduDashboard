# frozen_string_literal: true

Dir[Rails.root.join('lib/article_auditing/checks/*.rb')].each { |file| require_dependency file }

module ArticleAuditing
  # Loads the check configuration from config/article_audit_checks.yml and
  # builds check instances. The YAML is the single place that decides which
  # checks run, in what order, and on which engine:
  #
  #   tone:
  #     class: ArticleAuditing::Checks::Tone
  #     enabled: true
  #     provider: anthropic
  #     model: claude-opus-5-5
  #     effort: medium
  class Registry
    CONFIG_PATH = Rails.root.join('config/article_audit_checks.yml')

    def self.config
      YAML.load_file(CONFIG_PATH)
    end

    # Enabled checks, in config order.
    def self.enabled_checks
      config.filter_map { |key, entry| build(key, entry) if entry['enabled'] }
    end

    # A single check by key, whether or not it is enabled (for re-runs).
    def self.check(key)
      entry = config[key]
      raise ArgumentError, "unknown article audit check '#{key}'" if entry.nil?
      build(key, entry)
    end

    def self.keys
      config.keys
    end

    def self.build(key, entry)
      check = entry.fetch('class').constantize.new(entry.except('class', 'enabled'))
      raise ArgumentError, "#{entry['class']} has KEY #{check.key}, not #{key}" if check.key != key
      check
    end
  end
end
