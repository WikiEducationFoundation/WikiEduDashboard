# frozen_string_literal: true
require_dependency "#{Rails.root}/lib/tag_manager"

#= Procedures for creating a duplicate of an existing course for reuse
class CourseCloneManager
  def initialize(course:, user:, clone_assignments:, campaign_slug: nil)
    @course = course
    @user = user
    @campaign = Campaign.find_by(slug: campaign_slug) if campaign_slug
    @clone_assignments = clone_assignments
  end

  def clone!
    build_and_save_clone
    update_title_and_slug
    duplicate_timeline
    set_instructor
    tag_course
    add_flags
    add_campaigns

    copy_assignments if @clone_assignments
    return @clone
  # If a course with the new slug already exists — an incomplete clone of the
  # same course — then return the previously-created clone.
  rescue ActiveRecord::RecordNotUnique
    return Course.find_by(slug: @clone.slug)
  end

  private

  def set_courses_wikis
    # Make sure we don't duplicate the home_wiki CoursesWikis record
    wiki_ids = @course.wikis.map(&:id) - [@course.home_wiki_id]
    @clone.wikis.push Wiki.where(id: wiki_ids)
  end

  def set_placeholder_start_and_end_dates
    # The datepickers require an initial date, so we set these to today's date
    today = Time.zone.today
    @clone.start = today
    @clone.end = today
    @clone.timeline_start = today
    @clone.timeline_end = today
  end

  # Everything up to and including the first save is rebuilt from a fresh #dup
  # on each attempt, so a rolled-back attempt leaves no stale in-memory state
  # (built join records, the inverse has_one) behind. Losing the race for the
  # privacy-mode sequence re-rolls it and retries, as
  # CourseCreationManager#save_course does; any other collision is left to
  # #clone!, which treats it as an incomplete clone of the same course.
  def build_and_save_clone
    attempts = 0
    begin
      @clone = @course.dup
      set_courses_wikis
      set_placeholder_start_and_end_dates
      sanitize_clone_info
    rescue ActiveRecord::RecordNotUnique
      raise unless @course.confidential?
      raise unless (attempts += 1) < ObfuscateCourseIdentity::MAX_ATTEMPTS
      @confidential_identity = nil
      retry
    end
  end

  def sanitize_clone_info
    @clone.term = "CLONED FROM #{@course.term}"
    @clone.cloned_status = Course::ClonedStatus::PENDING
    @clone.title = confidential_identity.course_params[:title] if @course.confidential?
    @clone.slug = course_slug(@clone)
    @clone.passcode = GeneratePasscode.call
    @clone.submitted = false
    @clone.flags = {}
    # If a legacy course is cloned, switch the type to ClassroomProgramCourse.
    @clone.type = 'ClassroomProgramCourse' if @clone.legacy?
    save_clone_with_confidential_detail
    @clone = Course.find(@clone.id) # Re-load the course to ensure correct course type
    @clone.update_cache_from_timeslices # Reset the stats to 0
  end

  # The clone and its ConfidentialCourseDetail have to land together: a clone
  # left with an obfuscated title and no detail record would read as
  # non-confidential, dropping the guards and losing the real values.
  def save_clone_with_confidential_detail
    Course.transaction do
      @clone.save!
      clone_confidential_detail
    end
  end

  def update_title_and_slug
    @clone.update(
      title: @clone.title,
      slug: @clone.slug
    )
  end

  def copy_assignments
    CopyAvailableArticles.new(source: @course, target: @clone)
  end

  def duplicate_timeline
    # Be sure to create them in the correct order, to ensure that Course#reorder_weeks
    # does not misorder them on save. deep_clone does not necessarily create records
    # in the original order, so we clone each week rather than deep_clone the whole
    # course.
    @course.weeks.sort_by(&:order).each do |week|
      clone_week = week.deep_clone include: [:blocks]
      clone_week.course_id = @clone.id
      clone_week.save!
    end
    clear_meeting_days_and_due_dates
    update_wiki_ed_training_modules
  end

  def clear_meeting_days_and_due_dates
    @clone.update(day_exceptions: '', weekdays: '0000000', no_day_exceptions: false)

    # we can use `update_all` since there are no callbacks on Block
    # rubocop:disable Rails/SkipsModelValidations
    @clone.blocks.update_all(due_date: nil)
    # rubocop:enable Rails/SkipsModelValidations

    @clone.reload
  end

  # Replace first module with rest.
  MODULE_REPLACEMENTS = [
    [35, 69], # old "Add a fact" becomes new biography-focused version
    [38, 72, 73] # old "Bibliography + Outline" module with new separate modules
  ].freeze

  def update_wiki_ed_training_modules
    return unless Features.wiki_ed?

    MODULE_REPLACEMENTS.each do |replacement|
      # to_replace is a single_id, replace_with is an array of the rest
      to_replace, *replace_with = replacement
      @clone.blocks.each do |block|
        next unless block.training_module_ids.include? to_replace
        updated_module_ids = block.training_module_ids - [to_replace] + replace_with
        block.update(training_module_ids: updated_module_ids)
      end
    end
  end

  def set_instructor
    # Creating a course is analogous to self-enrollment; it is intentional on the
    # part of the user, so we associate the real name with the course.
    JoinCourse.new(user: @user,
                   course: @clone,
                   role: CoursesUsers::Roles::INSTRUCTOR_ROLE,
                   real_name: @user.real_name)
  end

  TAG_KEYS_TO_CARRY_OVER = %w[
    tricky_topic_areas
    working_individually
    working_in_groups
    research_write_assignment
    yes_sandboxes
    no_sandboxes
  ].freeze
  def tag_course
    tag_manager = TagManager.new(@clone)
    tag_manager.initial_tags(creator: @user)
    tag_manager.add(tag: 'cloned')
    @course.tags.each do |tag|
      next unless TAG_KEYS_TO_CARRY_OVER.include?(tag.key)
      tag_manager.add(tag: tag.tag, key: tag.key)
    end
  end

  FLAGS_TO_CARRY_OVER = [
    :peer_review_count,
    :retain_available_articles,
    :stay_in_sandbox,
    :no_sandboxes,
    :timeslice_duration
  ].freeze
  def add_flags
    FLAGS_TO_CARRY_OVER.each do |flag_key|
      next unless @course.flags.key? flag_key
      @clone.flags[flag_key] = @course.flags[flag_key]
    end
    # A clone is a new course, so it uses the ACUWT update path even when the
    # course it was cloned from does not.
    @clone.flags[:use_acuwt] = true
    @clone.save
  end

  def add_campaigns
    if @campaign
      @clone.campaigns << @campaign
    elsif Features.open_course_creation?
      copy_campaigns
    end
  end

  def copy_campaigns
    @course.campaigns.each do |campaign|
      CampaignsCourses.create(course: @clone, campaign:)
    end
  end

  def course_slug(course)
    "#{course.school}/#{course.title}_(#{course.term})".tr(' ', '_')
  end

  # A clone of a privacy-mode course inherits the obfuscated title through
  # #dup, which would give two courses the same privacy-mode number. Re-roll it
  # so the clone gets its own, and carry the real values over.
  def confidential_identity
    detail = @course.confidential_course_detail
    @confidential_identity ||= ObfuscateCourseIdentity.new({ title: detail.real_title,
                                                             school: detail.real_school })
  end

  def clone_confidential_detail
    return unless @course.confidential?
    ConfidentialCourseDetail.create!(course: @clone, **confidential_identity.detail_attributes)
  end
end
