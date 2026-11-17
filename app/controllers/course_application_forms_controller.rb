# frozen_string_literal: true

# Admin-only settings for a Scholars & Scientists course's application form:
# whether it is open, the intro applicants see, which Rapidfire question groups
# it asks, in order, and the email accepted applicants are sent. Wiki Education
# Dashboard only: the program, and the application review that follows, exist
# only there.
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
    { open: form[:open] == '1', intro: form[:intro], acceptance_email: form[:acceptance_email],
      question_group_ids: ordered_question_group_ids }
  end

  # The groups on the form, in page order, then the one picked to add, if any.
  # The model drops blanks and repeats and checks the ids.
  def ordered_question_group_ids
    form = params.fetch(:course_application_form, {})
    Array(form[:question_group_ids]) + [form[:add_question_group_id]]
  end

  # The groups that may join the form: anything not on it and not used in a
  # survey. A group can be on many courses' forms, so groups on other forms are
  # offered too.
  def set_question_group_choices
    in_surveys = SurveysQuestionGroup.select(:rapidfire_question_group_id)
    @question_group_choices = Rapidfire::QuestionGroup.where.not(id: @form.question_group_ids)
                                                      .where.not(id: in_surveys)
                                                      .order(:name).to_a
  end
end
