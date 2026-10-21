# frozen_string_literal: true

# The existing training module that an update draft was copied from (see
# CopyTrainingModuleToDraft): a snapshot of the module's yml files as they were
# at copy time, keyed by repository path, plus where each of its slides lives.
# ExportTrainingModuleUpdate diffs the draft against this snapshot.
class TrainingModuleDraftSource
  EDITABLE_SLIDE_KEYS = %w[id title content].freeze

  def initialize(attrs)
    @attrs = attrs.to_h.deep_stringify_keys
  end

  def module_slug
    @attrs['module_slug']
  end

  def module_path
    @attrs['module_path']
  end

  def files
    @attrs['files'] || {}
  end

  # [{ 'id', 'slug', 'path' }] in the module's original order.
  def slides
    @attrs['slides'] || []
  end

  def slide(id)
    slides.find { |slide| slide['id'] == id }
  end

  def slide_ids
    slides.pluck('id')
  end

  # Snapshot files that have since changed or disappeared on disk, which means
  # the exported patch might not apply cleanly.
  def stale_paths
    files.filter_map do |path, text|
      current = Rails.root.join(path)
      path unless current.exist? && current.read == text
    end
  end

  # What the composer shows about each original slide: its file, the other
  # modules that also list it, and the fields it has that can't be edited in
  # the composer, which the export leaves untouched.
  def slide_summaries(content_files)
    slides.map do |slide|
      data = YAML.safe_load(files[slide['path']].to_s, permitted_classes: [Symbol]) || {}
      {
        'id' => slide['id'],
        'slug' => slide['slug'],
        'filename' => File.basename(slide['path']),
        'shared_with' => content_files.modules_using_slide(slide['slug']) - [module_slug],
        'preserved_keys' => data.keys - EDITABLE_SLIDE_KEYS
      }
    end
  end

  def to_h
    @attrs
  end
end
