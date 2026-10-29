# frozen_string_literal: true

# Admin-only settings for a Scholars & Scientists course's application form:
# whether it is open, the intro applicants see, and which Rapidfire question
# groups it asks, in order. Wiki Education Dashboard only: the program, and the
# application review that follows, exist only there.
class CourseApplicationFormsController < ApplicationController
  layout 'admin'
  before_action :require_wiki_ed
  before_action :require_admin_permissions
  before_action :set_course_and_form

  def edit
    set_question_group_choices
  end

  def update
    if @form.update(form_params)
      redirect_to request.path, notice: t('course_application_forms.saved'), status: :see_other
    else
      set_question_group_choices
      render :edit, status: :unprocessable_content
    end
  end

  private

  def require_wiki_ed
    raise ActionController::RoutingError, 'Not Found' unless Features.wiki_ed?
  end

  def set_course_and_form
    @course = Course.find_by(slug: params[:slug])
    raise ActionController::RoutingError, 'Not Found' unless @course&.applications_allowed?

    @form = @course.course_application_form || @course.build_course_application_form
  end

  def form_params
    form = params.fetch(:course_application_form, {})
    { open: form[:open] == '1', intro: form[:intro],
      question_group_ids: ordered_question_group_ids }
  end

  # Each offered group has a position field, keyed by group id. Groups left
  # blank are not on the form; the rest are asked in position order.
  def ordered_question_group_ids
    group_ids = Rapidfire::QuestionGroup.pluck(:id).map(&:to_s)
    positions = params.dig(:course_application_form, :positions)&.permit(*group_ids).to_h
    positions.compact_blank
             .sort_by { |id, position| [position.to_i, id.to_i] }
             .map(&:first)
  end

  # The groups already on the form, in order, then every other group that may
  # join it: anything not used in a survey. A group can be on many courses'
  # forms, so groups on other forms are offered too.
  def set_question_group_choices
    on_form = @form.question_groups
    in_surveys = SurveysQuestionGroup.select(:rapidfire_question_group_id)
    others = Rapidfire::QuestionGroup.where.not(id: on_form.map(&:id))
                                     .where.not(id: in_surveys)
                                     .order(:name)
    @question_group_choices = on_form + others.to_a
  end
end
