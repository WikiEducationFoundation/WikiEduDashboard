# frozen_string_literal: true

class TrainingModulePresenter
  attr_reader :training_module, :progress_manager

  def initialize(user, mod_params)
    @user = user
    @params = mod_params
    @training_module = TrainingModule.find_by(slug: @params[:module_id])
    @training_library = TrainingLibrary.find_by(slug: @params[:library_id])
    @progress_manager = TrainingProgressManager.new(@user, @training_module)
    @routes = Rails.application.routes.url_helpers
  end

  def cta_button_text
    return I18n.t('training.start') unless progress_manager.module_progress.present?
    if progress_manager.module_completed?
      I18n.t('training.view')
    else
      I18n.t('training.continue', progress: progress_manager.module_progress)
    end
  end

  def cta_button_link
    first_element = @routes.training_module_path(@params[:library_id], @params[:module_id])
    last_element = if @progress_manager.module_completed? || @progress_manager.module_progress.nil?
                     @training_module.slides.first&.slug
                   else
                     last_slide_completed
                   end
    [first_element, last_element].join('/')
  end

  def cta_button_classes
    'btn btn-primary py2 icon icon-rt_arrow mx2 pull-left'
  end

  def should_show_ttc?
    return false unless @training_module.estimated_ttc
    training_modules_user.nil? || @progress_manager.module_completed?
  end

  private

  def training_modules_user
    return unless @user
    TrainingModulesUsers.find_by(
      user_id: @user.id,
      training_module_id: @training_module.id
    )
  end

  def last_slide_completed
    return unless @user
    training_modules_user.last_slide_completed
  end
end
