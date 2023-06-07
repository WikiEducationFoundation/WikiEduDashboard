# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/tag_manager"
require_dependency "#{Rails.root}/lib/article_utils"

#= Factory for handling the initial creation of a course
class CourseCreationManager
  attr_reader :wiki, :invalid_reason

  def initialize(course_params, wiki_params, scoping_methods, initial_campaign_params,
                 instructor_role_description, current_user)
    @scoping_methods = scoping_methods
    @course_params = course_params
    @wiki_params = wiki_params
    @initial_campaign_params = initial_campaign_params
    @role_description = instructor_role_description
    @instructor = current_user
    @overrides = {}
    set_wiki
    set_slug
    set_scoping_methods
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
    language = language_param.presence || Wiki.default_wiki.language
    project = project_param.presence || Wiki.default_wiki.project
    @wiki = Wiki.get_or_create(language: language.downcase, project: project.downcase)
    @overrides[:home_wiki] = @wiki
  rescue Wiki::InvalidWikiError
    @wiki = nil
  end

  def set_slug
    slug =  @course_params[:school].strip.presence || ''
    slug += "/#{@course_params[:title].strip}" if @course_params[:title].present?
    slug += "_(#{@course_params[:term].strip})" if @course_params[:term].present?
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
    @overrides[:passcode] = '' if @course_params[:passcode] == 'no-passcode'
    return if @course_params[:passcode].present?
    @overrides[:passcode] = GeneratePasscode.call
  end

  def set_course_type
    return if @course_params[:type].present?
    @overrides[:type] = Features.default_course_type
  end

  def set_initial_campaign
    return unless Features.open_course_creation?

    @overrides[:campaigns] = if @initial_campaign_params.present?
                               # rubocop:disable Layout/LineLength
                               [Campaign.find_by(id: @initial_campaign_params[:initial_campaign_id])]
                               # rubocop:enable Layout/LineLength
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

  def set_scoping_methods
    return if @scoping_methods.empty?
    add_categories_to_course @scoping_methods[:categories] if @scoping_methods[:categories]
  end

  def add_categories_to_course(category_params)
    depth = category_params[:depth]
    @overrides[:categories] = []

    category_params[:tracked].each do |category|
      name = ArticleUtils.format_article_title(category[:value])
      category = Category.find_or_create_by(name:, depth:, wiki: @wiki)
      @overrides[:categories] << category
    end
  end
end
