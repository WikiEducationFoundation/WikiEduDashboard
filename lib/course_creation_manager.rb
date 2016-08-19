# frozen_string_literal: true
require "#{Rails.root}/lib/tag_manager"

#= Factory for handling the initial creation of a course
class CourseCreationManager
  attr_reader :wiki

  def initialize(course_params, wiki_params, current_user)
    @course_params = course_params
    @wiki_params = wiki_params
    @instructor = current_user
    @overrides = {}
    set_wiki
  end

  def invalid_wiki?
    @wiki.id.nil?
  end

  def create
    set_slug
    set_passcode
    set_course_type
    set_initial_cohort
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
    @wiki = Wiki.find_or_create_by(language: language.downcase, project: project.downcase)
    @overrides[:home_wiki] = @wiki
  end

  def set_slug
    slug = String.new("#{@course_params[:school]}/#{@course_params[:title]}")
    slug << "_(#{@course_params[:term]})" unless @course_params[:term].blank?
    @overrides[:slug] = slug.tr(' ', '_')
  end

  def set_passcode
    @overrides[:passcode] = Course.generate_passcode
  end

  def set_course_type
    @overrides[:type] = ENV['default_course_type'] if ENV['default_course_type']
  end

  def set_initial_cohort
    @overrides[:cohorts] = [Cohort.default_cohort] if Features.open_course_creation?
  end

  def add_instructor_to_course
    CoursesUsers.create(user: @instructor,
                        course: @course,
                        role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
  end

  def add_tags_to_course
    TagManager.new(@course).initial_tags(creator: @instructor)
  end
end
