namespace :analytics do
  desc 'Report on the productivity of students, per cohort'
  task stats_per_cohort: 'batch:setup_logger' do
    Cohort.all.each do |cohort|
      course_ids = cohort.courses.pluck(:id)
      student_ids = CoursesUsers
                    .where(course_id: course_ids, role: 0)
                    .pluck(:user_id).uniq
      revisions = Revision.where(user_id: student_ids)
      revision_ids = revisions.pluck(:id)
      page_ids = revisions.pluck(:article_id).uniq
      article_ids = Article.where(namespace: 0, id: page_ids).pluck(:id)
      upload_ids = CommonsUpload.where(user_id: student_ids).pluck(:id)
      used_uploads = CommonsUpload
                     .where(id: upload_ids)
                     .where('usage_count > 0')
      used_count = used_uploads.count
      usage_count = used_uploads.sum(:usage_count)
      report = %(
#{cohort.slug}:
    #{student_ids.count} students
    #{revision_ids.count} revisions
    #{article_ids.count} articles edited
    #{upload_ids.count} files uploaded
    #{used_count} files in use
    #{usage_count} global usages
      )
      Rails.logger.info report
    end
  end

  desc 'Report on the productivity of all students'
  task combined_stats: 'batch:setup_logger' do
    course_ids = []
    Cohort.all.each do |cohort|
      course_ids += cohort.courses.pluck(:id)
    end
    student_ids = CoursesUsers
                  .where(course_id: course_ids, role: 0)
                  .pluck(:user_id).uniq
    revisions = Revision.where(user_id: student_ids)
    revision_ids = revisions.pluck(:id)
    page_ids = revisions.pluck(:article_id).uniq
    article_ids = Article.where(namespace: 0, id: page_ids).pluck(:id)
    upload_ids = CommonsUpload.where(user_id: student_ids).pluck(:id)
    used_uploads = CommonsUpload
                   .where(id: upload_ids)
                   .where('usage_count > 0')
    used_count = used_uploads.count
    usage_count = used_uploads.sum(:usage_count)
    report = %(
  #{student_ids.count} students
  #{revision_ids.count} revisions
  #{article_ids.count} articles edited
  #{upload_ids.count} files uploaded
  #{used_count} files in use
  #{usage_count} global usages
    )
    Rails.logger.info report
  end
end
