# frozen_string_literal: true

require 'zip'

# Builds a zip archive of production-layout yml files for a given
# TrainingModuleDraft. The archive contents are ready to drop into
# `training_content/wiki_ed/` in the repo.
#
# Zip structure:
#   modules/<slug>.yml
#   slides/<module_id>-<slug>/<NNNN>-<slide-slug>.yml
class ExportTrainingModuleDraft
  attr_reader :zip_bytes, :filename

  def initialize(draft)
    @draft = draft
    @filename = "#{draft.slug}-#{Time.current.strftime('%Y%m%d')}.zip"
    build
  end

  # Returns collisions between the draft's slide slugs and slugs in use by
  # already-loaded TrainingSlides. Admins should resolve these before export.
  def self.slide_slug_collisions(draft)
    draft_slugs = draft.slides.map { |s| s['slug'] }.compact_blank
    TrainingSlide.where(slug: draft_slugs).pluck(:slug)
  end

  private

  def build
    buffer = Zip::OutputStream.write_buffer do |zip|
      write_module_entry(zip)
      write_slide_entries(zip)
    end
    buffer.rewind
    @zip_bytes = buffer.read
  end

  def write_module_entry(zip)
    zip.put_next_entry("modules/#{@draft.slug}.yml")
    zip.write(module_yaml)
  end

  def write_slide_entries(zip)
    @draft.slides.each_with_index do |slide, index|
      zip.put_next_entry(slide_path(slide, index))
      zip.write(slide_yaml(slide, index))
    end
  end

  def slide_path(slide, index)
    id = @draft.slide_id_for(index)
    "slides/#{@draft.module_id}-#{@draft.slug}/#{format('%04d', id)}-#{slide['slug']}.yml"
  end

  def module_yaml
    hash = {
      'name' => @draft.name.to_s,
      'id' => @draft.module_id,
      'description' => @draft.description.to_s,
      'estimated_ttc' => @draft.estimated_ttc.to_s,
      'slides' => @draft.slides.map { |slide| { 'slug' => slide['slug'] } }
    }
    hash.to_yaml
  end

  # `summary:` is emitted as the empty string rather than nil because the
  # training view pipes it through Redcarpet, which rejects nil.
  def slide_yaml(slide, index)
    {
      'id' => @draft.slide_id_for(index),
      'title' => slide['title'].to_s,
      'summary' => '',
      'content' => slide['content'].to_s
    }.to_yaml
  end
end
