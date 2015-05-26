require "#{Rails.root}/lib/importers/revision_importer"

#= Cleaners
class Cleaners
  ####################
  # Articles Courses #
  ####################
  def self.remove_bad_articles_courses
    non_student_cus = CoursesUsers.where(role: [1, 2, 3, 4])
    non_student_cus.each do |nscu|
      remove_bad_articles_courses_for_course_user nscu
    end
  end

  ############
  # Articles #
  ############
  def self.remove_bad_articles_courses_for_course_user(course_user)
    course = course_user.course
    user_id = course_user.user_id
    # Check if the non-student user is also a student in the same course.
    return unless CoursesUsers.where(
      role: 0,
      course_id: course.id,
      user_id: user_id
    ).empty?

    user_articles = course_user.user.revisions
                    .where('date >= ?', course.start)
                    .where('date <= ?', course.end)
                    .pluck(:article_id)

    return if user_articles.empty?

    course_articles = course.articles.pluck(:id)
    possible_deletions = course_articles & user_articles

    to_delete = []
    possible_deletions.each do |pd|
      other_editors = Article.find(pd).editors - [user_id]
      course_editors = course.students & other_editors
      to_delete.push pd if other_editors.empty? || course_editors.empty?
    end

    # remove orphaned articles from the course
    course.articles.delete(Article.find(to_delete))
    Rails.logger.info(
      "Deleted #{to_delete.size} ArticlesCourses from #{course.title}"
    )
    # update course cache to account for removed articles
    course.update_cache unless to_delete.empty?
  end

  #############
  # Revisions #
  #############
  def self.repair_orphan_revisions
    article_ids = Article.all.pluck(:id)
    orphan_revisions = Revision.where
                       .not(article_id: article_ids)
                       .order('date ASC')

    Rails.logger.info "Found #{orphan_revisions.count} orphan revisions"
    return if orphan_revisions.blank?

    start = orphan_revisions.first.date - 1.day
    start = start.strftime('%Y%m%d')
    end_date = orphan_revisions.last.date + 1.day
    end_date = end_date.strftime('%Y%m%d')

    user_ids = orphan_revisions.pluck(:user_id).uniq
    users = User.where(id: user_ids)

    revision_data = RevisionImporter.get_revisions(users, start, end_date)
    RevisionImporter.import_revisions(revision_data)

    revs = RevisionImporter.get_revisions_from_import_data(revision_data)
    Rails.logger.info "Imported articles for #{revs.count} revisions"

    ArticlesCourses.update_from_revisions revs unless revs.blank?
  end
end
