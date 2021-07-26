# frozen_string_literal: true

#= Schedules a series of drip emails for advice, based on course timeline
class ScheduleCourseAdviceEmails
  def initialize(course, in_progress: false)
    @course = course
    @in_progress = in_progress
    schedule_emails
  end

  private

  def schedule_emails
    return unless @course.tag?('research_write_assignment')

    schedule_preliminary_work_email
    schedule_drafting_and_moving_email
    schedule_peer_review_email
    schedule_assessing_contributions_email
  end

  def schedule_preliminary_work_email
    return if @in_progress

    CourseAdviceEmailWorker.schedule_email(
      course: @course,
      subject: 'preliminary_work',
      send_at: @course.timeline_start
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
