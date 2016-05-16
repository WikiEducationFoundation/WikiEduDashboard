require "#{Rails.root}/lib/wiki_edits"
require "#{Rails.root}/lib/wiki_course_edits"
require "#{Rails.root}/lib/article_utils"

# Handles assignment data submitted by users
class AssignmentsManager
  ###############
  # Entry point #
  ###############
  def self.update_assignments(course, user_params, current_user)
    # Course may have been saved with no assignments, in which case there is no
    # assignment data to handle.
    return if user_params['assignments'].nil?

    user_params['assignments'].each do |assignment_data|
      handle_assignment_data(course, assignment_data, current_user)
    end

    WikiCourseEdits.new(action: :update_assignments, course: course, current_user: current_user)
    WikiCourseEdits.new(action: :update_course, course: course, current_user: current_user)
  end

  ####################
  # Internal methods #
  ####################
  def self.handle_assignment_data(course, assignment_data, current_user)
    assignment_data['course_id'] = course.id
    assignment_data['article_title'] = ArticleUtils.format_article_title(assignment_data['article_title'])

    assigned = Article.find_by(title: assignment_data['article_title'], namespace: 0)
    # We double check that the titles are equal to avoid false matches of case variants.
    # We can revise this once the database is set to use case-sensitive collation.
    if assigned && assigned.title == assignment_data['article_title']
      assignment_data['article_id'] = assigned.id
    end

    assignment = assignment_data['id'] ? Assignment.find_by(id: assignment_data['id']) : nil
    update_assignment assignment_data

    return unless assignment_data['deleted'] && assignment
    remove_assignment_template(course, assignment, current_user)
  end

  def self.remove_assignment_template(course, assignment, current_user)
    WikiCourseEdits.new(action: :remove_assignment,
                        course: course,
                        current_user: current_user,
                        assignment: assignment)
  end

  def self.update_assignment(assignment_object)
    id = assignment_object['id']
    if id.nil?
      Assignment.create assignment_object
    elsif assignment_object['deleted']
      Assignment.destroy id if Assignment.exists?(id)
    else
      Assignment.update id, assignment_object
    end
  rescue ActiveRecord::RecordNotUnique => error
    Raven.capture_exception error, level: 'warning'
  end
end
