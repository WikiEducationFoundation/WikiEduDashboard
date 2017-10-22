# frozen_string_literal: true

require "#{Rails.root}/lib/tag_manager"

#= Factory for handling the initial creation of a course
class CourseCreationManager
  attr_reader :wiki, :invalid_reason

  def initialize(course_params, wiki_params, initial_campaign_params,
                 instructor_role_description, current_user)
    @course_params = course_params
    @wiki_params = wiki_params
    @initial_campaign_params = initial_campaign_params
    @role_description = instructor_role_description
    @instructor = current_user
    @overrides = {}
    set_wiki
    set_slug
  end

  def valid?
    if invalid_wiki?
      @invalid_reason = I18n.t('courses.error.invalid_language_or_project')
      return false
    elsif invalid_slug?
      @invalid_reason = I18n.t('courses.error.invalid_slug')
      return false
    elsif duplicate_slug?
      @invalid_reason = I18n.t('courses.error.duplicate_slug', slug: @slug)
      return false
    end
    true
  end

  def create
    set_passcode
    set_course_type
    set_initial_campaign
    @course = Course.create(@course_params.merge(@overrides))
    add_instructor_to_course
    add_tags_to_course
    @course
  end

  private

  def set_wiki
    language_param = @wiki_params[:language]
    project_param = @wiki_params[:project]
    language = language_param.present? ? language_param : Wiki.default_wiki.language
    project = project_param.present? ? project_param : Wiki.default_wiki.project
    @wiki = Wiki.get_or_create(language: language.downcase, project: project.downcase)
    @overrides[:home_wiki] = @wiki
  rescue Wiki::InvalidWikiError
    @wiki = nil
  end

  def set_slug
    slug = @course_params[:school].blank? ? '' : @course_params[:school]
    slug += "/#{@course_params[:title]}" unless @course_params[:title].blank?
    slug += "_(#{@course_params[:term]})" unless @course_params[:term].blank?
    @slug = slug.tr(' ', '_')
    @overrides[:slug] = @slug
  end

  def invalid_wiki?
    @wiki&.id.nil?
  end

  def invalid_slug?
    # A valid slug should contain some non-blank text, followed by a forward slash,
    # followed by some more non-blank text. At least two non-blank parts should hence be present.
    slug_parts = @slug.split('/')
    slug_parts.reject!(&:blank?)
    slug_parts.size <= 1
  end

  def duplicate_slug?
    Course.find_by(slug: @slug).present?
  end

  def set_passcode
    @overrides[:passcode] = Course.generate_passcode
  end

  def set_course_type
    @overrides[:type] = Features.default_course_type
  end

  def set_initial_campaign
    return unless Features.open_course_creation?

    @overrides[:campaigns] = if @initial_campaign_params.present?
                               [Campaign.find_by_id(@initial_campaign_params[:initial_campaign_id])]
                             else
                               [Campaign.default_campaign]
                             end
  end

  def add_instructor_to_course
    # Creating a course is analogous to self-enrollment; it is intentional on the
    # part of the user, so we associate the real name with the course.
    JoinCourse.new(user: @instructor,
                   course: @course,
                   role: CoursesUsers::Roles::INSTRUCTOR_ROLE,
                   real_name: @instructor.real_name,
                   role_description: @role_description)
  end

  def add_tags_to_course
    TagManager.new(@course).initial_tags(creator: @instructor)
  end
end
