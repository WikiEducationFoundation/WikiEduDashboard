require "#{Rails.root}/lib/wiki_edits"
require "#{Rails.root}/lib/utils"

# Handles assignment data submitted by users
class AssignmentsManager
  def self.update_assignments(course, user_params, current_user)
    user_params['assignments'].each do |assignment_data|
      assignment_data['course_id'] = course.id
      assignment_data['article_title'] =
        Utils.format_article_title(assignment_data['article_title'])
      assigned = Article.find_by(title: assignment_data['article_title'], namespace: 0)
      if assigned
        # We double check that the titles are equal to avoid false matches of case variants.
        # We can revise this once the database is set to use case-sensitive collation.
        assignment_data['article_id'] =
          assigned.id if assigned.title == assignment_data['article_title']
      end

      assignment = nil
      assignment = Assignment.find_by(id: assignment_data['id']) if assignment_data['id']
      update_assignment assignment_data

      WikiEdits
        .remove_assignment(current_user, assignment) if assignment_data['deleted'] && assignment
    end

    WikiEdits.update_assignments(current_user, course)
    WikiEdits.update_course(course, current_user)
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
