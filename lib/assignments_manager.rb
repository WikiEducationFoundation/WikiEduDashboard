require "#{Rails.root}/lib/wiki_edits"
require "#{Rails.root}/lib/utils"

# Handles assignment data submitted by users
class AssignmentsManager
  def self.update_assignments(course, user_params, current_user)
    user_params['assignments'].each do |assignment|
      assignment['course_id'] = course.id
      assignment['article_title'] = Utils.format_article_title(assignment['article_title'])
      assigned = Article.find_by(title: assignment['article_title'], namespace: 0)
      if assigned
        # We double check that the titles are equal to avoid false matches of case variants.
        # We can revise this once the database is set to use case-sensitive collation.
        assignment['article_id'] = assigned.id if assigned.title == assignment['article_title']
      end
      update_util Assignment, assignment
    end

    WikiEdits.update_assignments(current_user, course)
    WikiEdits.update_course(course, current_user)
  end

  def self.update_util(model, object)
    if object['id'].nil?
      model.create object
    elsif object['deleted']
      model.destroy object['id']
    else
      model.update object['id'], object
    end
  rescue ActiveRecord::RecordNotUnique => error
    Raven.capture_exception error, level: 'warning'
  end
end
