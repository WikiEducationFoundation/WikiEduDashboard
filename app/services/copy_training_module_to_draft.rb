# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/training/training_content_files"

# Starts a TrainingModuleDraft from an existing yml-backed training module, so
# that an update to it can be prepared in the composer. The draft records the
# files it was copied from, and exports as a patch against them.
class CopyTrainingModuleToDraft
  attr_reader :draft

  def initialize(module_slug)
    raise CopyError, 'Wiki-based trainings cannot be copied.' if Features.wiki_trainings?
    @files = TrainingContentFiles.new
    @module_slug = module_slug.to_s
    @module_path = @files.module_path(@module_slug)
    raise CopyError, "No training module file for #{@module_slug.inspect}." unless @module_path
    perform
  end

  private

  def perform
    data = YAML.safe_load(module_text, permitted_classes: [Symbol]) || {}
    @slides = (data['slides'] || []).filter_map { |entry| copy_slide(entry['slug']) }
    @draft = TrainingModuleDraft.new(
      slug: available_draft_slug, name: data['name'], description: data['description'],
      estimated_ttc: data['estimated_ttc'], module_id: data['id'],
      slides: @slides.pluck(:draft_slide), source:
    ).save
  end

  def module_text
    @module_text ||= @module_path.read
  end

  # A listed slide with no file never shows up in the module, so the draft
  # leaves it out, and the export drops it from the module's slide list.
  def copy_slide(slug)
    path = @files.slide_path(slug)
    return unless path
    text = path.read
    data = YAML.safe_load(text, permitted_classes: [Symbol]) || {}
    {
      draft_slide: { 'id' => data['id'], 'slug' => slug, 'title' => data['title'].to_s,
                     'content' => data['content'].to_s },
      source_slide: { 'id' => data['id'], 'slug' => slug,
                      'path' => TrainingContentFiles.relative_path(path) },
      text:
    }
  end

  def source
    module_path = TrainingContentFiles.relative_path(@module_path)
    files = { module_path => module_text }
    @slides.each { |slide| files[slide[:source_slide]['path']] = slide[:text] }
    {
      'module_slug' => @module_slug,
      'module_path' => module_path,
      'copied_at' => Time.current.iso8601,
      'slides' => @slides.pluck(:source_slide),
      'files' => files
    }
  end

  # The module's own slug, unless another draft already has it.
  def available_draft_slug
    base = @module_slug.tr('_', '-').parameterize
    return base unless TrainingModuleDraft.exists?(base)
    (2..).lazy.map { |n| "#{base}-#{n}" }.find { |slug| !TrainingModuleDraft.exists?(slug) }
  end

  class CopyError < StandardError; end
end
