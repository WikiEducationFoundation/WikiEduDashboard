# frozen_string_literal: true

require 'yaml'
require_dependency "#{Rails.root}/lib/metrics_glossary/code_ref"

#= The metric glossary: YAML files in docs/metrics/ that define each metric
# the Dashboard computes, point at the code that computes it, and record
# places where the same name is computed differently. layout.yml arranges
# the metrics into sections that mirror how course pages group them. It backs
# the /metrics page and the drift checks in MetricsGlossary::Checker.
# See docs/metrics/README.md for the file format.
class MetricsGlossary
  DIR = Rails.root.join('docs', 'metrics')
  LAYOUT_FILE = 'layout.yml'
  SUPPORT_FILES = [LAYOUT_FILE, 'unclaimed.yml', 'fingerprints.yml'].freeze
  AUDIENCES = %w[public admin].freeze
  DEPLOYMENTS = %w[wiki_ed pe].freeze
  STATUSES = %w[undecided intentional bug fixed].freeze
  REPO_URL = 'https://github.com/WikiEducationFoundation/WikiEduDashboard'

  # A part of the page that mirrors a group of numbers on a course page: an
  # example of how they look, then an entry for each metric explained there,
  # and short notes on metrics explained in an earlier section.
  Section = Data.define(:key, :data, :metrics) do
    %w[title intro visual].each { |field| define_method(field) { data[field] } }

    def metric_keys = data['metrics'] || []
    # { metric_key => { 'label' => ..., 'text' => ... } }
    def notes = data['notes'] || {}
  end

  Metric = Data.define(:key, :file_key, :data, :implementations, :surfaces) do
    %w[name summary explanation fine_print].each { |field| define_method(field) { data[field] } }

    def aliases = data['aliases'] || []
    def audience = data['audience'] || 'public'
    def deployments = data['deployments'] || DEPLOYMENTS
    def columns = data['columns'] || []
    def admin_only? = audience == 'admin'
    def i18n_keys = surfaces.filter_map { |surface| surface['i18n'] }
    def places = surfaces.filter_map { |surface| surface['place'] }

    def visible_to?(admin:, deployment:)
      (admin || !admin_only?) && deployments.include?(deployment)
    end
  end

  Divergence = Data.define(:key, :file_key, :data, :code) do
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

  attr_reader :sections, :metrics, :divergences, :files, :duplicate_keys

  def initialize(dir = DIR)
    @files = metric_paths(dir).to_h do |path|
      [File.basename(path, '.yml'), YAML.safe_load_file(path) || {}]
    end
    @metrics = {}
    @divergences = {}
    @duplicate_keys = []
    @files.each { |file_key, raw| load_file(file_key, raw) }
    @sections = build_sections(dir)
  end

  # Sections with the entries and notes this viewer can see. A note stays
  # only if the entry it points back to is visible.
  def visible_sections(admin:, deployment:)
    visible = visible_metric_keys(admin:, deployment:)
    sections.filter_map do |section|
      shown = section.metrics.select { |metric| visible.include?(metric.key) }
      notes = section.notes.select { |key, _note| visible.include?(key) }
      next if shown.empty? && notes.empty?
      section.with(metrics: shown, data: section.data.merge('notes' => notes))
    end
  end

  def visible_metric_keys(admin:, deployment:)
    metrics.values.select { |metric| metric.visible_to?(admin:, deployment:) }.map(&:key).to_set
  end

  # Divergences involving at least one metric the viewer can see.
  def visible_divergences(admin:, deployment:)
    visible = visible_metric_keys(admin:, deployment:)
    divergences.values.select do |divergence|
      divergence.metric_keys.any? { |key| visible.include?(key) }
    end
  end

  # The section whose entry explains a metric.
  def section_for(metric_key)
    sections.find { |section| section.metric_keys.include?(metric_key) }
  end

  def divergences_for(metric_key)
    divergences.values.select { |divergence| divergence.metric_keys.include?(metric_key) }
  end

  def code_refs
    metrics.values.flat_map(&:implementations) + divergences.values.flat_map(&:code)
  end

  private

  def metric_paths(dir)
    Dir[File.join(dir, '*.yml')].sort.reject { |path| SUPPORT_FILES.include?(File.basename(path)) }
  end

  def load_file(file_key, raw)
    (raw['metrics'] || {}).each do |key, data|
      record_key(@metrics, key)
      @metrics[key] = Metric.new(key:, file_key:, data: data || {},
                                 implementations: code_refs_from(data&.dig('implementations')),
                                 surfaces: data&.dig('surfaces') || [])
    end
    (raw['divergences'] || {}).each do |key, data|
      record_key(@divergences, key)
      @divergences[key] = Divergence.new(key:, file_key:, data: data || {},
                                         code: code_refs_from(data&.dig('code')))
    end
  end

  def record_key(collection, key)
    @duplicate_keys << key if collection.key?(key)
  end

  def code_refs_from(list)
    (list || []).map { |hash| CodeRef.from_hash(hash) }
  end

  def build_sections(dir)
    path = File.join(dir, LAYOUT_FILE)
    layout = File.exist?(path) ? YAML.safe_load_file(path) || {} : {}
    (layout['sections'] || {}).map do |key, data|
      data ||= {}
      Section.new(key:, data:, metrics: (data['metrics'] || []).filter_map { |k| metrics[k] })
    end
  end
end
