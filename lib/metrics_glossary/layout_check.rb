# frozen_string_literal: true

class MetricsGlossary
  #= Checks docs/metrics/layout.yml: every metric is explained in exactly one
  # section, notes point back to metrics explained in another section, and
  # each section's example visual exists and links only to real entries.
  class LayoutCheck
    SECTION_FIELDS = %w[title intro visual metrics notes].freeze
    VISUALS_DIR = Rails.root.join('app', 'views', 'about_this_site', 'metrics_visuals')
    # Visual partials link each number to its entry with `href: '#key'`.
    VISUAL_LINK = /href: ['"]#([\w-]+)['"]/

    def initialize(glossary, visuals_dir = VISUALS_DIR)
      @glossary = glossary
      @visuals_dir = visuals_dir
    end

    def errors
      placement_errors + @glossary.sections.flat_map { |section| section_errors(section) }
    end

    private

    def placement_errors
      counts = @glossary.sections.flat_map(&:metric_keys).tally
      @glossary.metrics.keys.filter_map do |key|
        count = counts.fetch(key, 0)
        next if count == 1
        next "#{key}: isn't placed in any section of layout.yml" if count.zero?
        "#{key}: is placed in #{count} sections of layout.yml; it should be in one"
      end
    end

    def section_errors(section)
      problems = (section.data.keys - SECTION_FIELDS).map { |field| "unknown field #{field}" }
      problems << 'missing title' if section.title.blank?
      problems += (section.metric_keys - @glossary.metrics.keys).map do |key|
        "metric #{key} doesn't exist"
      end
      problems += note_problems(section) + visual_problems(section)
      problems.map { |problem| "layout.yml #{section.key}: #{problem}" }
    end

    def note_problems(section)
      section.notes.flat_map do |key, note|
        next ["note for #{key}, which doesn't exist"] unless @glossary.metrics.key?(key)
        if section.metric_keys.include?(key)
          next ["note for #{key}, which this section already explains"]
        end
        %w[label text].select { |field| !note.is_a?(Hash) || note[field].blank? }
                      .map { |field| "note for #{key} is missing #{field}" }
      end
    end

    def visual_problems(section)
      return [] if section.visual.blank?
      path = File.join(@visuals_dir, "_#{section.visual}.html.haml")
      return ["no visual partial _#{section.visual}.html.haml"] unless File.exist?(path)
      File.read(path).scan(VISUAL_LINK).flatten.uniq
          .reject { |anchor| anchors.include?(anchor) }
          .map { |anchor| "the visual links to ##{anchor}, which isn't an entry or note" }
    end

    # Entry anchors are metric keys; note anchors are <section>--<metric>.
    def anchors
      @anchors ||= @glossary.metrics.keys.to_set +
                   @glossary.sections.flat_map do |section|
                     section.notes.keys.map { |key| "#{section.key}--#{key}" }
                   end
    end
  end
end
