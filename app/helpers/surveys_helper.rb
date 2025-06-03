# frozen_string_literal: true

# Rubocop now wants us to remove instance methods from helpers. This is a good idea
# but will require a bit of refactoring. Find other instances of this disabling
# and fix all at once.
# rubocop:disable Rails/HelperInstanceVariable

module SurveysHelper
  include CourseHelper

  def survey_course_title
    if @course.nil? || !Features.wiki_ed?
      'Survey'
    else
      "Survey for #{@course.title} (#{@course.term})"
    end
  end

  def render_matrix_answer_labels(answer)
    render partial: 'rapidfire/answers/matrix_answer_labels',
           locals: { answer:, course: @course }
  end

  def survey_preview_url(survey)
    "#{survey_url(survey)}?preview"
  end

  def question_answer_field_name(form, multiple)
    name = "answer_group[#{form.object.question_id}][answer_text]"
    if multiple
      name + '[]'
    else
      name
    end
  end

  def survey_select(f, answer, course)
    multiple = answer.question.multiple
    field_name = question_answer_field_name(f, multiple)
    options = answer_options(answer, course)
              .collect { |o| o.is_a?(Array) ? [o[1].tr('_', ' ').to_s, o[0]] : o }
    return content_tag :div, 'remove me', data: { remove_me: true } if options.empty?
    select_tag(field_name, options_for_select(options),
               include_blank: multiple ? 'Select all that apply' : 'Select an option',
               required: required_question?(answer),
               multiple:)
  end

  def answer_options(answer, course)
    question = answer.question
    if !question.options.empty?
      question.options.collect { |q| [strip_tags(q), q, q] }
    elsif !course.nil?
      course_answer_options(question.course_data_type, course)
    end
  end

  def course_answer_options(type, course)
    case type
    when 'Students'
      course_student_choices(course)
    when 'Articles'
      course_article_choices(course)
    when 'WikiEdu Staff'
      course_wikiedu_staff_choices(course)
    end
  end

  def can_administer?
    current_user&.admin?
  end

  def required_question?(answer)
    answer.question.validation_rules[:presence].to_i == 1
  end

  def question_is_grouped?(answer)
    return false if answer.nil? || answer.question.nil?
    answer.question.validation_rules[:grouped].to_i == 1
  end

  def grouped_question(answer)
    answer.question.validation_rules[:grouped_question]
  end

  def question_group_locals(group, index, is_results_view:, answer_group_builders_by_id:, rapidfire_questions_by_id:) # rubocop:disable Layout/LineLength
    @question_group = group
    @answer_group_builder = answer_group_builders_by_id[@question_group.id]
    @id_to_question = rapidfire_questions_by_id
    prepare_question_data(is_results_view)

    return {
      question_group: @question_group,
      question_group_index: index,
      answer_group_builder: @answer_group_builder,
      results: is_results_view
    }
  end

  def prepare_question_data(results)
    question_presenters = @answer_group_builder.answers.map.with_index do |answer, index|
      answer.question = @id_to_question[answer.question_id]
      RapidfireQuestionPresenter.new(answer, index:, answer_group_builder: @answer_group_builder,
      is_results_view: results)
    end

    @visible_questions = question_presenters.reject do |presenter|
      presenter.results_view? && presenter.text_only?
    end
  end

  def question_row_classes(presenter, index, is_end_of_group)
    classes = ['survey__question-row']
    classes << 'matrix-row' if presenter.grouped_question?
    classes << presenter.required_class
    classes << (index.even? ? '' : 'odd')
    classes << 'last' if is_end_of_group
    classes.join(' ').strip
  end

  def question_conditional_string(question)
    return '' if question.nil?
    return '' unless valid_conditional_question?(question.conditionals)
    return question.conditionals
  end

  def course_data?(question_form)
    question_form.course_data_type.present?
  end

  def question_form_has_follow_up_question(question_form)
    question_form.follow_up_question_text.present?
  end

  def conditional_attribute(answer)
    return unless answer.question.conditionals?
    strip_tags(answer.question.conditionals).tr(' ', '_').tr("'", "\\'")
  end

  def numeric_min(answer)
    rule = answer.question.rules[:greater_than_or_equal_to]
    rule.empty? ? '0' : rule
  end

  def numeric_max(answer)
    rule = answer.question.rules[:less_than_or_equal_to]
    rule.empty? ? '999999999' : rule
  end

  def valid_conditional_question?(conditional_string)
    return false if conditional_string.nil?
    question_id = conditional_string.split('|').first.to_i
    Rapidfire::Question.exists?(question_id)
  end

  private

  def survey_notification_id(notification)
    return nil if notification == false || notification.nil?
    return notification.id
  end

  def survey_class_for_path(req, path)
    current_path_segments = req.path.split('/').reject(&:blank?)
    active_path = path.split('/').reject(&:blank?).last
    current_path_segments.include?(active_path) ? 'active' : nil
  end

  ######################
  # Setting the course #
  ######################

  # If at all possible, find the course to associate with this survey.
  # Setting a course is necessary for conditional features of surveys — question
  # groups that only apply to certain campaigns, or for courses with certain tags
  # — to work.
  # First go based on slug. Next, go based on notification.
  # For preview mode, fall back to the course_select dropdown.
  # For a real survey, fall back to the user's latest course.
  def set_course
    @course = find_course_by_slug(params[:course_slug]) if course_slug?
    @course ||= @notification.course if @notification.instance_of?(SurveyNotification)
    return if @course
    if preview_mode?
      set_course_via_select
    else
      fall_back_to_last_course_for_user
    end
  end

  def set_course_via_select
    @courses = Course.all
    render 'course_select'
  end

  def fall_back_to_last_course_for_user
    @course = current_user.courses.last
  end

  def preview_mode?
    params.key?(:preview)
  end

  ######################################
  # Methods called only from this file #
  ######################################

  def course_student_choices(course)
    students = course.courses_users.where(role: CoursesUsers::Roles::STUDENT_ROLE)
    students.collect { |cu| [cu.user.id, cu.user.username, contribution_link(cu).to_s] }
  end

  def course_article_choices(course)
    course.articles.collect do |a|
      [a.url, a.title, "<a href='#{a.url}' target='_blank'>#{a.title}</a>"]
    end
  end

  def course_wikiedu_staff_choices(course)
    staff = course.courses_users.where(role: CoursesUsers::Roles::WIKI_ED_STAFF_ROLE)
    staff.collect { |cu| [cu.user.id, cu.user.username, contribution_link(cu).to_s] }
  end

  def course_slug?
    params.key?(:course_slug)
  end
end

# rubocop:enable Rails/HelperInstanceVariable
