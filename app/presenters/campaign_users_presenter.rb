# frozen_string_literal: true

#= Presenter for building and filtering the users list on a campaign's /users page
class CampaignUsersPresenter
  def initialize(campaign:, params:, sort_column:, sort_direction:, page:)
    @campaign = campaign
    @params = params
    @sort_column = sort_column
    @sort_direction = sort_direction
    @page = page
  end

  def courses_users
    scope = CoursesUsers.where(
      course: @campaign.nonprivate_courses, role: CoursesUsers::Roles::STUDENT_ROLE
    ).eager_load(:user, :course)

    scope = filter_by_username(scope)
    scope = filter_by_revision_count(scope)
    scope = filter_by_course_title(scope)

    scope.order(order_clause).paginate(page: @page, per_page: 25)
  end

  private

  def order_clause
    unless @sort_column.present? && @sort_direction.present?
      return 'courses_users.revision_count DESC, users.username ASC'
    end

    column_map = {
      'username'       => 'users.username',
      'revision_count' => 'courses_users.revision_count',
      'title'          => 'courses.title'
    }

    sql_column = column_map[@sort_column] || @sort_column
    clause = "#{sql_column} #{@sort_direction}"
    clause += ', users.username ASC' unless @sort_column == 'username'
    clause
  end

  def filter_by_username(scope)
    return scope unless @params[:username].present?
    scope.where('users.username LIKE ?', "%#{@params[:username]}%")
  end

  def filter_by_revision_count(scope)
    if @params[:min_revision_count].present?
      scope = scope.where('courses_users.revision_count >= ?', @params[:min_revision_count])
    end
    if @params[:max_revision_count].present?
      scope = scope.where('courses_users.revision_count <= ?', @params[:max_revision_count])
    end
    scope
  end

  def filter_by_course_title(scope)
    return scope unless @params[:course_title].present?
    if @params[:course_title].is_a?(Array)
      scope.where(courses: { title: @params[:course_title] })
    else
      scope.where('courses.title LIKE ?', "%#{@params[:course_title]}%")
    end
  end
end
