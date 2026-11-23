# frozen_string_literal: true

require 'yaml'
require_dependency "#{Rails.root}/lib/metrics_glossary/code_ref"

#= The metric glossary: YAML files in docs/metrics/ that define each metric
# the Dashboard computes, point at the code that computes it, and record
# places where the same name is computed differently. It backs the /metrics
# page and the drift checks in MetricsGlossary::Checker.
# See docs/metrics/README.md for the file format.
class MetricsGlossary
  DIR = Rails.root.join('docs', 'metrics')
  SUPPORT_FILES = %w[unclaimed.yml fingerprints.yml].freeze
  AUDIENCES = %w[public admin].freeze
  DEPLOYMENTS = %w[wiki_ed pe].freeze
  STATUSES = %w[undecided intentional bug fixed].freeze
  REPO_URL = 'https://github.com/WikiEducationFoundation/WikiEduDashboard'

  Family = Data.define(:key, :title, :intro, :position, :metrics)

  Metric = Data.define(:key, :family_key, :data, :implementations, :surfaces) do
    %w[name summary definition].each { |field| define_method(field) { data[field] } }

    def audience = data['audience'] || 'public'
    def deployments = data['deployments'] || DEPLOYMENTS
    def columns = data['columns'] || []
    def related = data['related'] || []
    def admin_only? = audience == 'admin'
    def i18n_keys = surfaces.filter_map { |surface| surface['i18n'] }
    def places = surfaces.filter_map { |surface| surface['place'] }

    def visible_to?(admin:, deployment:)
      (admin || !admin_only?) && deployments.include?(deployment)
    end
  end

  Divergence = Data.define(:key, :family_key, :data, :code) do
    %w[title description status issue].each { |field| define_method(field) { data[field] } }

    def metric_keys = data['metrics'] || []
  end

  # The page reads the registry on each request in development, so edits to
  # the YAML show up without a restart; elsewhere it's loaded once.
  def self.current
    return new if Rails.env.development?
    @current ||= new
  end

  # The commit the running code came from (Capistrano writes REVISION into
  # each release), so code links match the deployed line numbers.
  def self.revision
    @revision ||= begin
      File.read(Rails.root.join('REVISION')).strip
    rescue Errno::ENOENT
      'master'
    end
  end

  attr_reader :families, :metrics, :divergences, :files, :duplicate_keys

  def initialize(dir = DIR)
    @files = family_paths(dir).to_h do |path|
      [File.basename(path, '.yml'), YAML.safe_load_file(path) || {}]
    end
    @metrics = {}
    @divergences = {}
    @duplicate_keys = []
    @files.each { |family_key, raw| load_family(family_key, raw) }
    @families = build_families
  end

  def visible_families(admin:, deployment:)
    families.filter_map do |family|
      shown = family.metrics.select { |metric| metric.visible_to?(admin:, deployment:) }
      family.with(metrics: shown) if shown.any?
    end
  end

  # Divergences involving at least one metric the viewer can see.
  def visible_divergences(admin:, deployment:)
    visible = visible_families(admin:, deployment:).flat_map(&:metrics).map(&:key)
    divergences.values.select { |divergence| divergence.metric_keys.intersect?(visible) }
  end

  def divergences_for(metric_key)
    divergences.values.select { |divergence| divergence.metric_keys.include?(metric_key) }
  end

  def code_refs
    metrics.values.flat_map(&:implementations) + divergences.values.flat_map(&:code)
  end

  private

  def family_paths(dir)
    Dir[File.join(dir, '*.yml')].sort.reject { |path| SUPPORT_FILES.include?(File.basename(path)) }
  end

  def load_family(family_key, raw)
    (raw['metrics'] || {}).each do |key, data|
      record_key(@metrics, key)
      @metrics[key] = Metric.new(key:, family_key:, data: data || {},
                                 implementations: code_refs_from(data&.dig('implementations')),
                                 surfaces: data&.dig('surfaces') || [])
    end
    (raw['divergences'] || {}).each do |key, data|
      record_key(@divergences, key)
      @divergences[key] = Divergence.new(key:, family_key:, data: data || {},
                                         code: code_refs_from(data&.dig('code')))
    end
  end

  def record_key(collection, key)
    @duplicate_keys << key if collection.key?(key)
  end

  def code_refs_from(list)
    (list || []).map { |hash| CodeRef.from_hash(hash) }
  end

  def build_families
    @files.map do |family_key, raw|
      family = raw['family'] || {}
      Family.new(key: family_key, title: family['title'], intro: family['intro'],
                 position: family['position'] || 0,
                 metrics: metrics.values.select { |metric| metric.family_key == family_key })
    end.sort_by(&:position)
  end
end
