# frozen_string_literal: true

class MetricsGlossary
  #= Requires every metric-like column and translation key (see Coverage) to
  # be claimed by a glossary entry or listed in docs/metrics/unclaimed.yml,
  # so a new metric can't land without someone deciding whether it needs an
  # entry.
  class CoverageCheck
    PATH = MetricsGlossary::DIR.join('unclaimed.yml')
    KINDS = { 'columns' => 'column', 'i18n' => 'translation key' }.freeze

    def initialize(glossary, coverage, path = PATH)
      @glossary = glossary
      @coverage = coverage
      @unclaimed = File.exist?(path) ? YAML.safe_load_file(path) || {} : {}
    end

    def errors
      KINDS.flat_map do |kind, noun|
        unaccounted_errors(kind, noun) + overclaimed_errors(kind, noun)
      end
    end

    private

    def found(kind)
      kind == 'columns' ? @coverage.metric_columns : @coverage.metric_i18n_keys
    end

    def claimed(kind)
      @claimed ||= {}
      @claimed[kind] ||= @glossary.metrics.values.flat_map do |metric|
        kind == 'columns' ? metric.columns : metric.i18n_keys
      end.to_set
    end

    def accounted_for?(kind, name)
      claimed(kind).include?(name) || pending(kind).include?(name) || ignored?(kind, name)
    end

    def pending(kind)
      (@unclaimed.dig('pending', kind) || []).to_set
    end

    # { name_or_prefix* => reason }
    def ignored(kind)
      @unclaimed.dig('ignored', kind) || {}
    end

    def ignored?(kind, name)
      ignored(kind).keys.any? do |pattern|
        pattern.end_with?('*') ? name.start_with?(pattern.delete_suffix('*')) : name == pattern
      end
    end

    def unaccounted_errors(kind, noun)
      found(kind).reject { |name| accounted_for?(kind, name) }.map do |name|
        "The #{noun} #{name} looks like a metric but has no glossary entry. Add it to an " \
          'entry in docs/metrics/, or list it in unclaimed.yml (pending, or ignored with a reason).'
      end
    end

    def overclaimed_errors(kind, noun)
      claimed_and_pending = (pending(kind) & claimed(kind)).map do |name|
        "The #{noun} #{name} has a glossary entry now; remove it from pending in unclaimed.yml."
      end
      gone = (pending(kind) - found(kind)).map do |name|
        "The #{noun} #{name} is pending in unclaimed.yml but no longer exists " \
          '(or no longer looks like a metric).'
      end
      bare_ignores = ignored(kind).select { |_name, reason| reason.blank? }.map do |name, _reason|
        "The ignored #{noun} #{name} in unclaimed.yml needs a reason."
      end
      claimed_and_pending + gone + bare_ignores
    end
  end
end
