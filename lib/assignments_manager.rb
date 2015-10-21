require "#{Rails.root}/lib/wiki_edits"
require "#{Rails.root}/lib/utils"

# Handles assignment data submitted by users
class AssignmentsManager
  def self.update_assignments(course, user_params, current_user)
    user_params['assignments'].each do |assignment|
      assignment['course_id'] = course.id
      assignment['article_title'] = Utils.format_article_title(assignment['article_title'])
      assigned = Article.find_by(title: assignment['article_title'])
      assignment['article_id'] = assigned.id unless assigned.nil?
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
  end
end
