# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/training/training_content_files"

# JSON for the training module composer. An update draft's file snapshot stays
# on the server; the composer gets what it needs to show what the update
# changes.
class TrainingModuleDraftPresenter
  def initialize(draft)
    @draft = draft
  end

  def as_json
    json = @draft.to_h.merge('updated_at' => @draft.updated_at)
    json['source'] = source_json if @draft.update?
    json
  end

  def summary
    {
      'slug' => @draft.slug,
      'name' => @draft.name,
      'module_id' => @draft.module_id,
      'updates' => @draft.source&.module_slug,
      'slide_count' => @draft.slides.length,
      'updated_at' => @draft.updated_at
    }
  end

  private

  def source_json
    content_files = TrainingContentFiles.new
    source = @draft.source
    {
      'module_slug' => source.module_slug,
      'module_path' => source.module_path,
      'slides' => source.slide_summaries(content_files),
      'stale_paths' => source.stale_paths,
      'changes' => ExportTrainingModuleUpdate.new(@draft, content_files:).change_list
    }
  end
end
