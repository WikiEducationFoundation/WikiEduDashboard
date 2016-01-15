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

  def self.rebuild_articles_courses(courses=nil)
    courses ||= Course.current
    courses.each do |course|
      ArticlesCourses.update_from_course(course)
    end
  end

  ############
  # Articles #
  ############
  def self.remove_bad_articles_courses_for_course_user(course_user)
    course = course_user.course
    user_id = course_user.user_id
    # Check if the non-student user is also a student in the same course.
    return if course_user.user.student?(course)

    user_articles = find_user_articles(course_user, course)
    return if user_articles.empty?

    course_articles = course.articles.pluck(:id)
    possible_deletions = course_articles & user_articles

    to_delete = []
    possible_deletions.each do |a_id|
      to_delete.push a_id unless other_editors_in_course?(a_id, user_id, course)
    end

    # remove orphaned articles from the course
    course.articles.delete(Article.find(to_delete))
    Rails.logger.info(
      "Deleted #{to_delete.size} ArticlesCourses from #{course.title}"
    )
    # update course cache to account for removed articles
    course.update_cache unless to_delete.empty?
  end

  def self.other_editors_in_course?(article_id, user_id, course)
    other_editors = Article.find(article_id).editors - [user_id]
    return false if other_editors.empty?
    course_editors = course.students & other_editors
    return false if course_editors.empty?
    true
  end

  def self.find_user_articles(course_user, course)
    course_user
      .user.revisions
      .where('date >= ?', course.start)
      .where('date <= ?', course.end)
      .pluck(:article_id)
  end

  #############
  # Revisions #
  #############
  def self.repair_orphan_revisions
    orphan_revisions = find_orphan_revisions
    return if orphan_revisions.blank?

    start = before_earliest_revision(orphan_revisions)
    end_date = after_latest_revision(orphan_revisions)

    user_ids = orphan_revisions.pluck(:user_id).uniq
    users = User.where(id: user_ids)

    revision_data = RevisionImporter.get_revisions(users, start, end_date)
    RevisionImporter.import_revisions(revision_data)

    revs = RevisionImporter.get_revisions_from_import_data(revision_data)
    Rails.logger.info "Imported articles for #{revs.count} revisions"

    return if revs.blank?
    new_rev_user_ids = revs.map(&:user_id)
    course_ids = CoursesUsers
                 .where(user_id: new_rev_user_ids, role: CoursesUsers::Roles::STUDENT_ROLE)
                 .pluck(:course_id).uniq
    course_ids.each do |course_id|
      ArticlesCourses.update_from_course(Course.find(course_id))
    end
  end

  def self.find_orphan_revisions
    article_ids = Article.all.pluck(:id)
    orphan_revisions = Revision.where
                       .not(article_id: article_ids)
                       .order('date ASC')

    Rails.logger.info "Found #{orphan_revisions.count} orphan revisions"
    orphan_revisions
  end

  def self.before_earliest_revision(revisions)
    date = revisions.first.date - 1.day
    date.strftime('%Y%m%d')
  end

  def self.after_latest_revision(revisions)
    date = revisions.last.date + 1.day
    date.strftime('%Y%m%d')
  end

  ###############
  # Assignments #
  ###############
  def self.repair_case_variant_assignment_titles
    require "#{Rails.root}/lib/utils"
    assignments = Assignment.all
    assignments.each do |assignment|
      article_title = assignment.article_title
      article_id = assignment.article_id
      if article_id && Article.exists?(article_id)
        canonical_title = Article.find(article_id).title
        next if article_title == canonical_title
        update_assignment_title_to_match_article(assignment, canonical_title)
      elsif title_improperly_formatted?(article_title)
        assignment.article_title = Utils.format_article_title(article_title)
        assignment.save
      end
    end
  end

  def self.update_assignment_title_to_match_article(assignment, canonical_title)
    assignment.article_title = canonical_title
    assignment.save
  rescue ActiveRecord::RecordNotUnique
    # This may happen if one assignment has spaces instead of underscores for the title.
    # In that case, we can just remove the duplicate assignment.
    assignment.destroy
  end

  def self.title_improperly_formatted?(article_title)
    article_title != Utils.format_article_title(article_title)
  end

  def self.match_assignment_titles_with_case_variant_articles_that_exist(count=nil)
    require "#{Rails.root}/lib/utils"

    assignments = Assignment.where(article_id: nil)
    assignments = assignments.last(count) if count
    assignments.each do |assignment|
      possibly_bad_title = assignment.article_title
      next unless possibly_bad_title == Utils.format_article_title(possibly_bad_title.downcase)
      title_search_result = first_article_search_result(possibly_bad_title)
      next if possibly_bad_title == title_search_result
      next unless title_search_result.downcase == possibly_bad_title.downcase.tr(' ', '_')
      assignment.article_title = title_search_result
      assignment.save
    end
  end

  def self.first_article_search_result(search_term)
    require "#{Rails.root}/lib/wiki"
    query = { list: 'search',
              srsearch: search_term,
              srnamespace: 0,
              srlimit: 1 }
    response = Wiki.query(query)
    return '' if response.nil?
    results = response.data['search']
    return '' if results.empty?
    results = results[0]['title'].tr(' ', '_')
    results
  end
end
