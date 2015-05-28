namespace :analytics do
  desc 'Count number of articles edited per cohort'
  task articles_edited: 'batch:setup_logger' do
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
      used_uploads = CommonsUpload.where(id: upload_ids).where('usage_count > 0')
      used_count = used_uploads.count
      usage_count = used_uploads.sum(:usage_count)
      Rails.logger.info "#{cohort.slug}:"
      Rails.logger.info "    #{student_ids.count} students"
      Rails.logger.info "    #{revision_ids.count} revisions"
      Rails.logger.info "    #{article_ids.count} articles edited"
      Rails.logger.info "    #{upload_ids.count} files uploaded"
      Rails.logger.info "    #{used_count} files in use"
      Rails.logger.info "    #{usage_count} global usages"
    end
  end
end
