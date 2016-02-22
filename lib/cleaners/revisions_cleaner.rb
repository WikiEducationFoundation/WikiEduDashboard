require "#{Rails.root}/lib/importers/revision_importer"

#= Routines for keeping revision data consistent
class RevisionsCleaner
  #############
  # Revisions #
  #############
  def self.repair_orphan_revisions
    orphan_revisions = find_orphan_revisions
    return if orphan_revisions.blank?

    start = before_earliest_revision(orphan_revisions)
    end_date = after_latest_revision(orphan_revisions)

    # TODO: Can we use orphan_revisions.users directly?
    user_ids = orphan_revisions.pluck(:user_id).uniq
    users = User.where(id: user_ids)

    # TODO: Make a smarter guess than this.
    # FIXME: Also, why can't I: wikis = users.courses.assignments.wikis.uniq
    wikis = users.map(&:courses).reduce(:|).map(&:assignments).reduce(:|).map(&:wikis).reduce(:|).uniq

    revision_data = RevisionImporter.get_revisions(users, start, end_date, wikis)
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
end
