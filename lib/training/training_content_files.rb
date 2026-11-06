# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/training/training_base"

# Read-only index of the training content yml files on disk: which file defines
# each module and slide, and which modules list each slide. This is what the
# repository holds, which may differ from what is loaded into the database.
class TrainingContentFiles
  SLIDE_FILENAME = /\A(\d+)-(.+)\.yml\z/

  def initialize(base_path: TrainingBase.base_path)
    @base_path = Pathname.new(base_path)
  end

  # Summaries of every module file, sorted by name.
  def modules
    module_data.map do |slug, data|
      { 'slug' => slug, 'name' => data['name'], 'id' => data['id'] }
    end.sort_by { |summary| summary['name'].to_s.downcase }
  end

  def module_path(slug)
    module_files[slug]
  end

  def slide_path(slug)
    slide_files[slug]&.fetch(:path)
  end

  def slide_ids
    slide_files.values.pluck(:id)
  end

  def modules_using_slide(slide_slug)
    module_data.filter_map do |slug, data|
      slug if (data['slides'] || []).pluck('slug').include?(slide_slug)
    end
  end

  # The path as it appears in the repository, and so in a git diff.
  def self.relative_path(path)
    Pathname.new(path).relative_path_from(Rails.root).to_s
  end

  private

  def module_files
    @module_files ||= @base_path.glob('modules/*.yml').to_h do |path|
      [path.basename('.yml').to_s, path]
    end
  end

  def module_data
    @module_data ||= module_files.transform_values do |path|
      YAML.safe_load_file(path, permitted_classes: [Symbol]) || {}
    end
  end

  # Slide slugs come from filenames, the same way YamlTrainingLoader derives them.
  def slide_files
    @slide_files ||= @base_path.glob('slides/**/*.yml').each_with_object({}) do |path, index|
      match = path.basename.to_s.match(SLIDE_FILENAME)
      index[match[2]] ||= { path:, id: match[1].to_i } if match
    end
  end
end
