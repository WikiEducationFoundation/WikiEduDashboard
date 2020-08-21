# frozen_string_literal: true

json.course do
  user_role = current_user&.role(@course) || CoursesUsers::Roles::VISITOR_ROLE

  json.call(@course, :id, :title, :description, :start, :end, :school,
            :subject, :slug, :url, :submitted, :expected_students, :timeline_start,
            :timeline_end, :day_exceptions, :weekdays, :no_day_exceptions,
            :updated_at, :string_prefix, :use_start_and_end_times, :type,
            :home_wiki, :character_sum,  :upload_count, :uploads_in_use_count,
            :upload_usages_count, :cloned_status, :flags, :level, :format, :private,
            :closed?, :training_library_slug, :peer_review_count, :needs_update,
            :update_until, :withdrawn)

  json.wikis @course.wikis, :language, :project
  json.timeline_enabled @course.timeline_enabled?
  json.academic_system @course.academic_system
  json.home_wiki_bytes_per_word @course.home_wiki.bytes_per_word
  json.home_wiki_edits_enabled @course.home_wiki.edits_enabled?
  json.wiki_edits_enabled @course.wiki_edits_enabled?
  json.assignment_edits_enabled @course.assignment_edits_enabled?
  json.wiki_course_page_enabled @course.wiki_course_page_enabled?
  json.enrollment_edits_enabled @course.enrollment_edits_enabled?
  json.account_requests_enabled @course.account_requests_enabled?
  json.online_volunteers_enabled @course.online_volunteers_enabled?
  json.stay_in_sandbox @course.stay_in_sandbox?
  json.term @course.cloned_status == 1 ? '' : @course.term
  json.legacy @course.legacy?
  json.ended @course.end < Time.zone.now
  json.published CampaignsCourses.exists?(course_id: @course.id)
  json.closed @course.closed?
  json.enroll_url "#{request.base_url}#{course_slug_path(@course.slug)}/enroll/"
  json.wiki_string_prefix @course.home_wiki.string_prefix

  json.created_count number_to_human @course.new_article_count
  json.edited_count number_to_human @course.article_count
  json.edit_count number_to_human @course.revision_count
  json.student_count @course.user_count
  json.trained_count @course.trained_count
  json.word_count number_to_human @course.word_count
  json.references_count number_to_human @course.references_count
  json.view_count number_to_human @course.view_sum
  json.character_sum_human number_to_human @course.character_sum
  json.syllabus @course.syllabus.url if @course.syllabus.file?
  json.updates average_delay: @course.flags['average_update_delay'],
               last_update: @course.flags['update_logs']&.values&.last

  if user_role.zero? # student role
    json.incomplete_assigned_modules @course.training_progress_manager
                                            .incomplete_assigned_modules(current_user)
  end

  if user_role >= 0 # user enrolled in course
    json.survey_notifications(current_user.survey_notifications.active) do |notification|
      if notification.course.id == @course.id
        json.id notification.id
        json.survey_url course_survey_url(notification).to_s
        json.message notification.survey_assignment.custom_banner_message
      end
    end
  end

  if user_role.positive? # non-student role
    json.passcode_required @course.passcode_required?
    json.passcode @course.passcode
    json.canUploadSyllabus true
    json.requestedAccounts @course.requested_accounts.count if @course.account_requests_enabled?
  elsif @course.passcode
    # If there is a passcode, send a placeholder value. If not, send empty string.
    json.passcode @course.passcode.blank? ? '' : '****'
    json.canUploadSyllabus false
  end

  if user_role == 1 # instructor
    exeriment_presenter = ExperimentsPresenter.new(@course)
    json.experiment_notification exeriment_presenter.notification if exeriment_presenter.experiment
  end
end
