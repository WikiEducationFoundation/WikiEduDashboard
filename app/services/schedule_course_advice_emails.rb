# frozen_string_literal: true

#= Schedules a series of drip emails for advice, based on course timeline
class ScheduleCourseAdviceEmails
  def initialize(course, in_progress: false)
    @course = course
    @in_progress = in_progress
  end

  def schedule_emails
    return unless @course.tag?('research_write_assignment')

    schedule_biographies_email
    # schedule_hype_video_email
    schedule_preliminary_work_email
    schedule_choosing_an_article_email
    schedule_bibliographies_email
    schedule_drafting_and_moving_email
    schedule_peer_review_email
    schedule_assessing_contributions_email
  end

  private

  def schedule_biographies_email
    return unless @course.tag?('biographies')

    CourseAdviceEmailWorker.schedule_email(
      course: @course,
      subject: 'biographies',
      send_at: Time.zone.now
    )
  end

  def schedule_hype_video_email
    # 3 days before the assignment starts
    send_date = @course.timeline_start - 3.days
    return if send_date.past?

    CourseAdviceEmailWorker.schedule_email(
      course: @course,
      subject: 'hype_video',
      send_at: send_date
    )
  end

  def schedule_preliminary_work_email
    return if @in_progress

    CourseAdviceEmailWorker.schedule_email(
      course: @course,
      subject: 'preliminary_work',
      send_at: @course.timeline_start
    )
  end

  # This one only goes to courses that are took the
  # 'explore_to_find_articles' option in the Assignment Wizard
  def schedule_choosing_an_article_email
    block = @course.find_block_by_title 'Choose possible topics'
    return unless block
    return if too_late?(block)

    CourseAdviceEmailWorker.schedule_email(
      course: @course,
      subject: 'choosing_an_article',
      send_at: block.calculated_date.to_datetime
    )
  end

  # This goes to 'choose_articles_from_list' courses
  # at the point of choosing articles, and to 'explore_to_find_articles'
  # courses the week after at the "finalize topic" stage
  def schedule_bibliographies_email
    block = @course.find_block_by_title 'Finalize your topic and find sources'
    block ||= @course.find_block_by_title 'Choose your article'
    return unless block
    return if too_late?(block)

    CourseAdviceEmailWorker.schedule_email(
      course: @course,
      subject: 'bibliographies',
      send_at: block.calculated_date.to_datetime
    )
  end

  def schedule_drafting_and_moving_email
    block = @course.find_block_by_title 'Start drafting your'
    return unless block
    return if too_late?(block)

    CourseAdviceEmailWorker.schedule_email(
      course: @course,
      subject: 'drafting_and_moving',
      send_at: block.calculated_date.to_datetime
    )
  end

  def schedule_peer_review_email
    block = @course.find_block_by_title 'Peer review'
    return unless block
    return if too_late?(block)

    CourseAdviceEmailWorker.schedule_email(
      course: @course,
      subject: 'peer_review',
      send_at: block.calculated_date.to_datetime
    )
  end

  def schedule_assessing_contributions_email
    block = @course.find_block_by_title 'Final article'
    return unless block
    return if too_late?(block)

    CourseAdviceEmailWorker.schedule_email(
      course: @course,
      subject: 'assessing_contributions',
      send_at: block.calculated_date.to_datetime
    )
  end

  def too_late?(block)
    block.calculated_date.past?
  end
end
