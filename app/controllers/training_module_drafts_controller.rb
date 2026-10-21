# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/training/training_content_files"

class TrainingModuleDraftsController < ApplicationController
  before_action :require_admin_permissions

  def index
    respond_to do |format|
      format.html
      format.json do
        drafts = TrainingModuleDraft.all.map { |d| TrainingModuleDraftPresenter.new(d).summary }
        render json: { drafts: drafts }
      end
    end
  end

  def show
    respond_to do |format|
      format.html { render :index }
      format.json do
        draft = TrainingModuleDraft.find(params[:slug])
        render json: { draft: draft_json(draft) }
      end
    end
  rescue TrainingModuleDraft::NotFound
    render json: { error: 'Draft not found' }, status: :not_found
  rescue Psych::SyntaxError => e
    render json: { error: "Draft yml is malformed: #{e.message}" },
           status: :unprocessable_content
  end

  def create
    slug = build_slug(draft_params[:slug], draft_params[:name])
    if TrainingModuleDraft.exists?(slug)
      return render json: { error: "A draft with slug #{slug.inspect} already exists." },
                    status: :unprocessable_content
    end
    draft = TrainingModuleDraft.new(draft_params.merge(slug: slug))
    draft.save
    render json: { draft: draft_json(draft) }, status: :created
  rescue TrainingModuleDraft::InvalidSlug => e
    render json: { error: e.message }, status: :unprocessable_content
  end

  # Starts an update draft from an existing training module.
  def copy
    draft = CopyTrainingModuleToDraft.new(params[:module_slug]).draft
    render json: { draft: draft_json(draft) }, status: :created
  rescue CopyTrainingModuleToDraft::CopyError, TrainingModuleDraft::InvalidSlug => e
    render json: { error: e.message }, status: :unprocessable_content
  end

  def existing_modules
    modules = Features.wiki_trainings? ? [] : TrainingContentFiles.new.modules
    render json: { modules: }
  end

  def update
    draft = TrainingModuleDraft.find(params[:slug])
    rename_to = pending_rename(draft)
    # Fail fast on rename errors before persisting any content changes, so a
    # taken or invalid slug doesn't silently update the old file.
    precheck_rename!(rename_to) if rename_to
    apply_updates(draft)
    draft.save
    draft.rename!(rename_to) if rename_to
    render json: { draft: draft_json(draft) }
  rescue TrainingModuleDraft::NotFound
    render json: { error: 'Draft not found' }, status: :not_found
  rescue TrainingModuleDraft::SlugTaken, TrainingModuleDraft::InvalidSlug => e
    render json: { error: e.message }, status: :unprocessable_content
  end

  def destroy
    draft = TrainingModuleDraft.find(params[:slug])
    draft.destroy
    render json: { success: true }
  rescue TrainingModuleDraft::NotFound
    render json: { error: 'Draft not found' }, status: :not_found
  end

  def parse_paste
    slides = ParseSlidesFromMarkdown.new(params[:markdown]).slides
    render json: { slides: slides }
  rescue ParseSlidesFromMarkdown::InvalidFormat => e
    render json: { error: e.message }, status: :unprocessable_content
  end

  def export
    draft = TrainingModuleDraft.find(params[:slug])
    return export_update(draft) if draft.update?
    export = ExportTrainingModuleDraft.new(draft)
    send_data export.zip_bytes, type: 'application/zip',
                                filename: export.filename,
                                disposition: 'attachment'
  rescue TrainingModuleDraft::NotFound
    render json: { error: 'Draft not found' }, status: :not_found
  end

  def collisions
    draft = TrainingModuleDraft.find(params[:slug])
    render json: { collisions: ExportTrainingModuleDraft.slide_slug_collisions(draft) }
  rescue TrainingModuleDraft::NotFound
    render json: { error: 'Draft not found' }, status: :not_found
  end

  def existing_slide_slugs
    render json: { slugs: TrainingSlide.pluck(:slug) }
  end

  private

  def export_update(draft)
    export = ExportTrainingModuleUpdate.new(draft)
    if export.changed_files.empty?
      return render json: { error: 'The draft has no changes to export.' },
                    status: :unprocessable_content
    end
    patch = export.patch(author_name: current_user.real_name.presence || current_user.username,
                         author_email: current_user.email)
    send_data patch, type: 'text/x-patch', filename: export.filename, disposition: 'attachment'
  end

  def draft_json(draft)
    TrainingModuleDraftPresenter.new(draft).as_json
  end

  def pending_rename(draft)
    requested = draft_params[:slug].presence
    requested if requested && requested != draft.slug
  end

  def precheck_rename!(new_slug)
    TrainingModuleDraft.validate_slug!(new_slug)
    return unless TrainingModuleDraft.exists?(new_slug)
    raise TrainingModuleDraft::SlugTaken,
          "A draft with slug #{new_slug.inspect} already exists."
  end

  def apply_updates(draft)
    draft.name = draft_params[:name] if draft_params.key?(:name)
    draft.description = draft_params[:description] if draft_params.key?(:description)
    draft.estimated_ttc = draft_params[:estimated_ttc] if draft_params.key?(:estimated_ttc)
    draft.slides = sanitized_slides if draft_params.key?(:slides)
  end

  def draft_params
    params.require(:draft).permit(:slug, :name, :description, :estimated_ttc,
                                  slides: [:id, :slug, :title, :content])
  end

  def sanitized_slides
    (draft_params[:slides] || []).map do |slide|
      {
        'id' => slide[:id],
        'slug' => slide[:slug].to_s.strip,
        'title' => slide[:title].to_s,
        'content' => slide[:content].to_s
      }
    end
  end

  def build_slug(requested, name)
    candidate = requested.presence || name.to_s.parameterize
    TrainingModuleDraft.validate_slug!(candidate)
    candidate
  end
end
