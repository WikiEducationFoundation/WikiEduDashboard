# frozen_string_literal: true

#= Procedures for creating a duplicate of an existing course for reuse
class CourseCloneManager
  def initialize(course, user)
    @course = course
    @user = user
  end

  def clone!
    @clone = @course.dup
    set_placeholder_start_and_end_dates
    sanitize_clone_info
    update_title_and_slug
    duplicate_timeline
    clear_meeting_days_and_due_dates
    set_instructor
    tag_course
    copy_campaigns if Features.open_course_creation?
    return @clone
  # If a course with the new slug already exists — an incomplete clone of the
  # same course — then return the previously-created clone.
  rescue ActiveRecord::RecordNotUnique
    return Course.find_by(slug: @clone.slug)
  end

  private

  def set_placeholder_start_and_end_dates
    # The datepickers require an initial date, so we set these to today's date
    today = Time.zone.today
    @clone.start = today
    @clone.end = today
    @clone.timeline_start = today
    @clone.timeline_end = today
  end

  def sanitize_clone_info
    @clone.term = "CLONED FROM #{@course.term}"
    @clone.cloned_status = Course::ClonedStatus::PENDING
    @clone.slug = course_slug(@clone)
    @clone.passcode = Course.generate_passcode
    @clone.submitted = false
    @clone.flags = {}
    # If a legacy course is cloned, switch the type to ClassroomProgramCourse.
    @clone.type = 'ClassroomProgramCourse' if @clone.legacy?
    @clone.save!
    @clone = Course.find(@clone.id) # Re-load the course to ensure correct course type
    @clone.update_cache
  end

  def update_title_and_slug
    @clone.update_attributes(
      title: @clone.title,
      slug: @clone.slug
    )
  end

  def duplicate_timeline
    # Be sure to create them in the correct order, to ensure that Course#order_weeks
    # does not misorder them on save. deep_clone does not necessarily create records
    # in the original order, so we clone each week rather than deep_clone the whole
    # course.
    @course.weeks.sort_by(&:order).each do |week|
      clone_week = week.deep_clone include: [{ blocks: :gradeable }]
      clone_week.course_id = @clone.id
      clone_week.save!
    end
  end

  def clear_meeting_days_and_due_dates
    @clone.update_attributes(day_exceptions: '',
                             weekdays: '0000000',
                             no_day_exceptions: false)
    @clone.blocks.update_all(due_date: nil)
    @clone.reload
  end

  def set_instructor
    # Creating a course is analogous to self-enrollment; it is intentional on the
    # part of the user, so we associate the real name with the course.
    JoinCourse.new(user: @user,
                   course: @clone,
                   role: CoursesUsers::Roles::INSTRUCTOR_ROLE,
                   real_name: @user.real_name)
  end

  TAG_KEYS_TO_CARRY_OVER = ['tricky_topic_areas'].freeze
  def tag_course
    tag_manager = TagManager.new(@clone)
    tag_manager.initial_tags(creator: @user)
    tag_manager.add(tag: 'cloned')
    @course.tags.each do |tag|
      next unless TAG_KEYS_TO_CARRY_OVER.include?(tag.key)
      tag_manager.add(tag: tag.tag, key: tag.key)
    end
  end

  def copy_campaigns
    @course.campaigns.each do |campaign|
      CampaignsCourses.create(course: @clone, campaign: campaign)
    end
  end

  def course_slug(course)
    "#{course.school}/#{course.title}_(#{course.term})".tr(' ', '_')
  end
end
