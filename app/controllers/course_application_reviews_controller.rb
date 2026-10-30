# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/analytics/course_applications_csv_builder"

# Admin-only review of the applications to a Scholars & Scientists course: the
# list, each application's answers and staff notes, accepting (which enrolls
# the applicant) and declining, and a CSV export. Wiki Education Dashboard only.
class CourseApplicationReviewsController < ApplicationController
  layout 'admin'
  before_action :require_wiki_ed
  before_action :require_admin_permissions
  before_action :set_course
  before_action :set_application, only: %i[show update accept decline]

  def index
    respond_to do |format|
      format.html do
        @applications = @course.course_applications.includes(:user, :decided_by)
                               .order(:created_at)
      end
      format.csv do
        send_data CourseApplicationsCsvBuilder.new(@course).generate_csv,
                  type: 'text/csv', disposition: 'attachment',
                  filename: "#{@course.slug}-applications-#{Time.zone.today}.csv".tr('/', '-')
      end
    end
  end

  def show
    @answer_groups = ordered_answer_groups
  end

  # Saves the staff notes.
  def update
    @application.update!(staff_notes: params.dig(:course_application, :staff_notes))
    redirect_to application_path, notice: t('course_application_reviews.notes_saved'),
                                  status: :see_other
  end

  def accept
    acceptance = AcceptCourseApplication.new(application: @application, staff: current_user)
    unless acceptance.success?
      flash[:error] = t("courses.join_failure_details.#{acceptance.failure}")
    end
    redirect_to application_path, status: :see_other
  end

  def decline
    DeclineCourseApplication.new(application: @application, staff: current_user)
    redirect_to application_path, status: :see_other
  end

  private

  def require_wiki_ed
    raise ActionController::RoutingError, 'Not Found' unless Features.wiki_ed?
  end

  def set_course
    @course = Course.find_by(slug: params[:slug])
    raise ActionController::RoutingError, 'Not Found' unless @course&.applications_allowed?
  end

  def set_application
    @application = @course.course_applications.find(params[:id])
  end

  # The application's page: this request's path, less any action segment.
  def application_path
    request.path.sub(%r{/(accept|decline)\z}, '')
  end

  # In the form's group order, then any groups since removed from the form.
  def ordered_answer_groups
    group_order = @course.course_application_form&.question_group_ids || []
    @application.answer_groups.includes(:question_group, answers: :question)
                .sort_by { |group| group_order.index(group.question_group_id) || group_order.size }
  end
end
