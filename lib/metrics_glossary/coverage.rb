# frozen_string_literal: true

class MetricsGlossary
  #= Finds the things that look like metrics, so the checker can require each
  # one to have a glossary entry or an explicit place in unclaimed.yml:
  # stored metric-like database columns, and the translation keys that label
  # or explain stats.
  class Coverage
    SCHEMA_PATH = Rails.root.join('db', 'schema.rb')
    LOCALE_PATH = Rails.root.join('config', 'locales', 'en.yml')
    # Column names built around a stat word, e.g. character_sum_ms, view_sum,
    # uploads_in_use_count, recent_revisions, average_views, stats_hash.
    STAT_WORDS = %w[count sum views score stats total average rate retained trained recent].freeze
    METRIC_COLUMN = /(?:\A|_)(?:#{STAT_WORDS.join('|')})(?:_|\z)/
    METRIC_TYPES = %w[integer bigint float decimal text boolean].freeze
    # Tables that only hold stats; all their data columns count.
    METRIC_TABLES = %w[course_stats system_stats facilitator_stats retention_stats].freeze
    META_COLUMNS = %w[created_at updated_at snapshot_date computed_at].freeze
    METRIC_KEY = /\Ametrics\.|_doc(?:_\w+)?\z/

    def schema_columns
      @schema_columns ||= parse_schema.map { |table, column, _type| "#{table}.#{column}" }.to_set
    end

    def metric_columns
      @metric_columns ||= parse_schema.filter_map do |table, column, type|
        next if META_COLUMNS.include?(column) || column.end_with?('_id')
        next unless METRIC_TABLES.include?(table) ||
                    (METRIC_TYPES.include?(type) && METRIC_COLUMN.match?(column))
        "#{table}.#{column}"
      end.to_set
    end

    def i18n_keys
      @i18n_keys ||= flatten_keys(YAML.safe_load_file(LOCALE_PATH)['en']).to_set
    end

    def metric_i18n_keys
      @metric_i18n_keys ||= i18n_keys.grep(METRIC_KEY).to_set
    end

    private

    def parse_schema
      @parse_schema ||= begin
        table = nil
        File.readlines(SCHEMA_PATH).filter_map do |line|
          if (match = line.match(/^\s*create_table "(\w+)"/))
            table = match[1]
            next
          end
          match = line.match(/^\s*t\.(\w+)\s+"(\w+)"/)
          [table, match[2], match[1]] if match && table
        end
      end
    end

    def flatten_keys(hash, prefix = nil)
      hash.flat_map do |key, value|
        full_key = [prefix, key].compact.join('.')
        value.is_a?(Hash) ? flatten_keys(value, full_key) : [full_key]
      end
    end
  end
end
