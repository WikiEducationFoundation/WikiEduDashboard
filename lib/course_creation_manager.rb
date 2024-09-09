# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/tag_manager"
require_dependency "#{Rails.root}/lib/article_utils"
require_dependency "#{Rails.root}/lib/experiments/no_sandboxes_fall_2024_experiment"

#= Factory for handling the initial creation of a course
class CourseCreationManager
  attr_reader :wiki, :invalid_reason

  # rubocop:disable Metrics/ParameterLists
  def initialize(course_params, wiki_params, scoping_methods, initial_campaign_params,
                 instructor_role_description, current_user, ta_support)
    @scoping_methods = scoping_methods
    @ta_support = ta_support
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
  # rubocop:enable Metrics/ParameterLists

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
    # Returns the course object, either as an in-memory object if save fails,
    # or as a persisted object if save is successful.
    set_passcode
    set_course_type
    set_initial_campaign
    @course = Course.new(@course_params.merge(@overrides))
    if @course.save
      add_instructor_to_course
      add_tags_to_course
      process_experiments
    end
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
                               [Campaign.find_by(
                                 id: @initial_campaign_params[:initial_campaign_id]
                               )]
                             else
                               [Campaign.default_campaign].compact
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
    TagManager.new(@course).initial_tags(creator: @instructor, ta_support: @ta_support)
  end

  def process_experiments
    NoSandboxesFall2024Experiment.new(@course, @instructor)
  end

  def create_all_category(categories, source)
    categories.each do |category|
      title = category[:value][:title]
      depth = category[:value][:depth] || 0

      wiki_language = category[:value][:wiki][:language]
      wiki_project = category[:value][:wiki][:project]
      wiki = Wiki.get_or_create(language: wiki_language.downcase, project: wiki_project.downcase)

      name = ArticleUtils.format_article_title(title)
      category = Category.find_or_create_by(name:, depth:, wiki:, source:)
      @overrides[:categories] << category
    end
  end

  def set_scoping_methods
    return if @scoping_methods.nil? || @scoping_methods.empty?
    @overrides[:categories] = []

    add_categories_to_course @scoping_methods[:categories] if @scoping_methods[:categories]
    add_templates_to_course @scoping_methods[:templates] if @scoping_methods[:templates]
    add_page_pile_to_course @scoping_methods[:pagepile] if @scoping_methods[:pagepile]
    add_petscan_to_course @scoping_methods[:petscan] if @scoping_methods[:petscan]
  end

  def add_categories_to_course(category_params)
    create_all_category(category_params[:tracked], 'category')
  end

  def add_templates_to_course(template_params)
    create_all_category(template_params[:include], 'template')
  end

  def add_page_pile_to_course(pagepile_params)
    create_all_category(pagepile_params[:ids], 'pileid')
  end

  def add_petscan_to_course(petscan_params)
    create_all_category(petscan_params[:psids], 'psid')
  end
end
