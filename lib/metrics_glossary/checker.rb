# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/metrics_glossary/coverage"
require_dependency "#{Rails.root}/lib/metrics_glossary/coverage_check"
require_dependency "#{Rails.root}/lib/metrics_glossary/fingerprints"
require_dependency "#{Rails.root}/lib/metrics_glossary/layout_check"

class MetricsGlossary
  #= The drift checks for the glossary. Each method returns a list of
  # human-readable problems, empty when everything is in order. Run them with
  # `bin/rails metrics:check`; spec/lib/metrics_glossary_spec.rb runs them in CI.
  class Checker
    METRIC_FIELDS = %w[name aliases summary explanation fine_print audience deployments
                       implementations surfaces columns].freeze
    DIVERGENCE_FIELDS = %w[title metrics description code status issue].freeze
    SURFACE_KINDS = %w[i18n place].freeze

    attr_reader :glossary, :coverage, :fingerprints

    def initialize(glossary = MetricsGlossary.new, coverage: Coverage.new,
                   fingerprints: nil, unclaimed_path: CoverageCheck::PATH)
      @glossary = glossary
      @coverage = coverage
      @fingerprints = fingerprints || Fingerprints.new(glossary)
      @coverage_check = CoverageCheck.new(glossary, coverage, unclaimed_path)
    end

    def errors
      schema_errors + reference_errors + coverage_errors + fingerprint_errors
    end

    # The YAML has the fields it should, and its cross-references line up.
    def schema_errors
      glossary.duplicate_keys.map { |key| "#{key}: defined more than once" } +
        LayoutCheck.new(glossary).errors +
        glossary.metrics.values.flat_map { |metric| metric_errors(metric) } +
        glossary.divergences.values.flat_map { |divergence| divergence_errors(divergence) }
    end

    # Code pointers, translation keys and columns all still exist.
    def reference_errors
      glossary.code_refs.filter_map(&:error).uniq +
        glossary.metrics.values.flat_map { |metric| missing_key_and_column_errors(metric) }
    end

    def coverage_errors
      @coverage_check.errors
    end

    # Formula methods and constants haven't changed since the entries that
    # point at them were last checked.
    def fingerprint_errors
      owners = fingerprints.owners_by_target
      fingerprints.changed.map do |target|
        "#{target} changed since the glossary entries that point at it " \
          "(#{owners[target].join(', ')}) were last checked. Re-read them in docs/metrics/, " \
          'update them if the calculation changed, then run `bin/rails metrics:accept`.'
      end + fingerprints.unrecorded.map do |target|
        "#{target} has no recorded fingerprint. Once the entries that point at it are " \
          'accurate, run `bin/rails metrics:accept`.'
      end + fingerprints.stale.map do |target|
        "#{target} is in fingerprints.yml but is no longer fingerprinted. " \
          'Run `bin/rails metrics:accept`.'
      end
    end

    private

    def metric_errors(metric)
      problems = unknown_fields(metric.data, METRIC_FIELDS) +
                 missing_fields(metric.data, %w[name summary explanation])
      problems << "audience must be one of #{AUDIENCES.join(', ')}" unless valid_audience?(metric)
      problems << 'unknown deployment' unless (metric.deployments - DEPLOYMENTS).empty?
      problems << 'needs at least one implementation' if metric.implementations.empty?
      problems << 'aliases must be a list of labels' unless valid_aliases?(metric)
      problems += surface_problems(metric)
      problems.map { |problem| "#{metric.key}: #{problem}" }
    end

    def surface_problems(metric)
      bad_surfaces = metric.surfaces.reject { |surface| valid_surface?(surface) }
      kinds = SURFACE_KINDS.join(', ')
      bad_surfaces.map { |surface| "surface #{surface.inspect} needs one of #{kinds}" }
    end

    def valid_aliases?(metric)
      metric.aliases.is_a?(Array) && metric.aliases.all?(String)
    end

    def divergence_errors(divergence)
      problems = unknown_fields(divergence.data, DIVERGENCE_FIELDS) +
                 missing_fields(divergence.data, %w[title description])
      problems << "status must be one of #{STATUSES.join(', ')}" unless valid_status?(divergence)
      problems << 'issue must be an issue number' unless valid_issue?(divergence)
      problems << 'needs at least one metric' if divergence.metric_keys.empty?
      problems += missing_metrics(divergence.metric_keys).map do |key|
        "metric #{key} doesn't exist"
      end
      problems.map { |problem| "#{divergence.key}: #{problem}" }
    end

    def valid_audience?(metric)
      AUDIENCES.include?(metric.audience)
    end

    def valid_status?(divergence)
      STATUSES.include?(divergence.status)
    end

    def valid_issue?(divergence)
      divergence.issue.nil? || divergence.issue.is_a?(Integer)
    end

    def missing_fields(data, required)
      required.select { |field| data[field].blank? }.map { |field| "missing #{field}" }
    end

    def missing_key_and_column_errors(metric)
      missing_keys = metric.i18n_keys.reject { |key| coverage.i18n_keys.include?(key) }
      missing_columns = metric.columns.reject { |column| coverage.schema_columns.include?(column) }
      missing_keys.map { |key| "#{metric.key}: no translation key #{key} in en.yml" } +
        missing_columns.map { |column| "#{metric.key}: no column #{column} in db/schema.rb" }
    end

    def valid_surface?(surface)
      surface.is_a?(Hash) && surface.keys.one? && SURFACE_KINDS.include?(surface.keys.first)
    end

    def missing_metrics(keys)
      keys - glossary.metrics.keys
    end

    def unknown_fields(data, allowed)
      (data.keys - allowed).map { |field| "unknown field #{field}" }
    end
  end
end
