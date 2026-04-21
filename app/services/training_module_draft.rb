# frozen_string_literal: true

# File-backed, non-ActiveRecord representation of an in-progress training module.
#
# Drafts live as individual yml files in `training_content_drafts/`. Admins use
# the composer UI to create, edit, and export them; export produces the final
# production-layout yml files in `training_content/wiki_ed/`.
#
# Unlike TrainingModule, drafts are never loaded into the database.
class TrainingModuleDraft
  SLUG_PATTERN = /\A[a-z0-9][a-z0-9-]*\z/
  # Slugs that would collide with Rails conventions or with composer subpath
  # routes that take priority over the :slug show route. Names containing an
  # underscore (existing_slide_slugs, parse_paste) are already ruled out by
  # SLUG_PATTERN, so they don't need to appear here.
  RESERVED_SLUGS = %w[new edit index].freeze
  DIRNAME = 'training_content_drafts'

  attr_accessor :slug, :name, :description, :estimated_ttc, :module_id, :slides

  def self.directory
    Rails.root.join(DIRNAME)
  end

  def self.all
    return [] unless directory.exist?
    directory.children.select { |path| path.extname == '.yml' }
             .filter_map { |path| safely_load(path) }
             .sort_by { |draft| -draft.updated_at.to_i }
  end

  def self.safely_load(path)
    from_file(path)
  rescue StandardError => e
    Rails.logger.warn("Skipping unreadable draft #{path}: #{e.message}")
    nil
  end

  def self.find(slug)
    validate_slug!(slug)
    path = directory.join("#{slug}.yml")
    raise NotFound, "No draft found for slug #{slug.inspect}" unless path.exist?
    from_file(path)
  end

  def self.exists?(slug)
    return false unless slug.to_s.match?(SLUG_PATTERN)
    directory.join("#{slug}.yml").exist?
  end

  def self.from_file(path)
    data = YAML.safe_load_file(path, permitted_classes: [Symbol]) || {}
    draft = new(data)
    draft.slug ||= path.basename('.yml').to_s
    draft.instance_variable_set(:@updated_at, path.mtime)
    draft
  end

  def self.validate_slug!(slug)
    str = slug.to_s
    raise InvalidSlug, "Invalid draft slug #{slug.inspect} (use lowercase letters, " \
                       'digits, hyphens)' unless str.match?(SLUG_PATTERN)
    raise InvalidSlug, "#{slug.inspect} is a reserved slug" if RESERVED_SLUGS.include?(str)
  end

  def initialize(attrs = {})
    attrs = attrs.transform_keys(&:to_s)
    @slug = attrs['slug']
    @name = attrs['name']
    @description = attrs['description']
    @estimated_ttc = attrs['estimated_ttc']
    @module_id = attrs['module_id']
    @slides = (attrs['slides'] || []).map { |s| normalize_slide(s) }
  end

  def updated_at
    @updated_at ||= Time.current
  end

  def save
    self.class.validate_slug!(slug)
    ensure_directory
    assign_module_id
    File.write(path, to_yaml_body)
    @updated_at = File.mtime(path)
    self
  end

  def destroy
    self.class.validate_slug!(slug)
    File.delete(path) if path.exist?
  end

  # Rename a saved draft's slug: writes the new file and removes the old one.
  # Raises InvalidSlug or SlugTaken as appropriate.
  def rename!(new_slug)
    return self if new_slug == slug
    self.class.validate_slug!(new_slug)
    raise SlugTaken, "A draft with slug #{new_slug.inspect} already exists." \
      if self.class.exists?(new_slug)
    old_path = path
    @slug = new_slug
    save
    File.delete(old_path) if old_path.exist? && old_path != path
    self
  end

  def path
    self.class.directory.join("#{slug}.yml")
  end

  def to_h
    {
      'slug' => slug,
      'name' => name,
      'description' => description,
      'estimated_ttc' => estimated_ttc,
      'module_id' => module_id,
      'slides' => slides.map(&:dup)
    }
  end

  def slide_id_for(index)
    (module_id || 0) * 100 + index + 1
  end

  private

  def ensure_directory
    FileUtils.mkdir_p(self.class.directory)
  end

  def assign_module_id
    return if module_id && module_id_available?(module_id)
    @module_id = next_available_module_id
  end

  def module_id_available?(candidate)
    in_db = TrainingModule.where(id: candidate).exists?
    in_other_drafts = self.class.all.any? { |d| d.slug != slug && d.module_id == candidate }
    !in_db && !in_other_drafts
  end

  def next_available_module_id
    used = TrainingModule.pluck(:id) + self.class.all.reject { |d| d.slug == slug }.map(&:module_id)
    (used.compact.max || 0) + 1
  end

  def normalize_slide(slide)
    slide = (slide || {}).to_h.transform_keys(&:to_s)
    slug = slide['slug'].to_s
    validate_slide_slug!(slug)
    {
      'slug' => slug,
      'title' => slide['title'].to_s,
      'content' => slide['content'].to_s
    }
  end

  def validate_slide_slug!(slug)
    return if slug.empty? || slug.match?(SLUG_PATTERN)
    raise InvalidSlug, "Invalid slide slug #{slug.inspect} " \
                       '(use lowercase letters, digits, hyphens)'
  end

  def to_yaml_body
    to_h.to_yaml
  end

  class NotFound < StandardError; end
  class InvalidSlug < ArgumentError; end
  class SlugTaken < StandardError; end
end
