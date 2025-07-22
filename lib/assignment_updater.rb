# frozen_string_literal: true

#= Keeps assignments updated to match moving articles
class AssignmentUpdater
  # Update article ids for Assignments that lack them, if an Article with the
  # same title exists in mainspace.
  # This does a case-insensitive match, so it will find cases where no article
  # with the exact title was found when the assignment was first created, but
  # the user edited the actual intended article and so it got imported later.
  def self.update_assignment_article_ids_and_titles
    Assignment.where(article_id: nil).find_each do |assignment|
      title = assignment.article_title.tr(' ', '_')
      article = Article.where(namespace: 0, wiki_id: assignment.wiki_id, deleted: false)
                       .find_by(title:)
      next if article.nil?
      update_assignment_from_article(assignment, article)
    end
  end

  def self.update_assignment_from_article(assignment, article)
    assignment.article_id = article.id
    assignment.article_title = article.title # update assignment to match case
    assignment.save!
  rescue ActiveRecord::RecordInvalid
    # If there is already an assignment for article_title/course_id/user_id/role/wiki_id,
    # then clean the article id
    assignment.reload
    assignment.article_id = nil
    assignment.save
  end

  # This method will update the assignments to match the Article title, in
  # case the Article moved titles.
  def self.update_assignments_for_article(article)
    article.assignments.each do |assignment|
      update_assignment_from_article(assignment, article)
    end
  end

  # If an article is set as deleted, we don't want any assignment to be associated
  # to it. This method cleans the article_id field for those assignments.
  def self.clean_assignment_for_deleted_article(article)
    article.assignments.each do |assignment|
      assignment.update(article_id: nil)
    end
  end
end
