# frozen_string_literal: true

#= Schedules a series of drip emails for advice, based on course timeline
class ScheduleCourseAdviceEmails
  def initialize(course)
    @course = course
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
    # find timeline start
    # send
  end

  def schedule_drafting_and_moving_email
    block = @course.find_block_by_title 'Start drafting your'
    return unless block

    # send
  end

  def schedule_peer_review_email
    block = @course.find_block_by_title 'Peer review'
    return unless block

    # send
  end

  def schedule_assessing_contributions_email
    block = @course.find_block_by_title 'Final article'
    return unless block

    # send
  end
end
