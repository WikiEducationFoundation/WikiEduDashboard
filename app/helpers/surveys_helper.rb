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

  # rubocop:disable Metrics/MethodLength
  def question_group_locals(surveys_question_group, index, total, is_results_view:)
    @question_group = surveys_question_group.rapidfire_question_group
    @answer_group_builder = Rapidfire::AnswerGroupBuilder.new(params: {},
                                                              user: current_user,
                                                              question_group: @question_group)
    @questions = surveys_question_group
                 .rapidfire_question_group
                 .questions
                 .includes(answers: { user: :survey_notifications })

    @id_to_question = {}
    @questions.each do |question|
      @id_to_question[question.id] = question
    end

    @question_answers_count = Rapidfire::Answer
                              .where(question_id: @questions.pluck(:id))
                              .group(:question_id).count

    @answer_group_builder.answers.each do |answer|
      question = @id_to_question[answer.question_id]
      answer.question = question
    end

    return { question_group: @question_group,
      answer_group_builder: @answer_group_builder,
      question_group_index: index,
      surveys_question_group:,
      total:,
      results: is_results_view }
  end
  # rubocop:enable Metrics/MethodLength

  def question_conditional_string(question)
    return '' if question.nil?
    unless question.conditionals.nil?
      question_id = question.conditionals.split('|').first.to_i
      begin
        Rapidfire::Question.find(question_id)
      rescue ActiveRecord::RecordNotFound
        return ''
      end
    end
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
    string = strip_tags(answer.question.conditionals).tr(' ', '_').tr("'", "\\'")
    string
  end

  def numeric_min(answer)
    rule = answer.question.rules[:greater_than_or_equal_to]
    rule.empty? ? '0' : rule
  end

  def numeric_max(answer)
    rule = answer.question.rules[:less_than_or_equal_to]
    rule.empty? ? '999999999' : rule
  end

  private

  def survey_notification_id(notification)
    return nil if notification == false || notification.nil?
    return notification.id
  end

  def survey_class_for_path(req, path)
    current_path_segments = req.path.split('/').reject(&:blank?)
    active_path = path.split('/').reject(&:blank?).last
    current_path_segments.last == active_path ? 'active' : nil
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
