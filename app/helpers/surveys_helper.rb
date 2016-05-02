module SurveysHelper
  include CourseHelper

  def survey_course_title
    if @course.nil?
      'Survey'
    else
      "Survey for #{@course.title}"
    end
  end

  def render_answer_form_helper(answer, form)
    partial = question_type(answer)
    render partial: "rapidfire/answers/#{partial}", locals: { f: form, answer: answer, course: @course }
  end

  def render_matrix_answer_labels(answer)
    render partial: 'rapidfire/answers/matrix_answer_labels', locals: { answer: answer, course: @course }
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
    options = answer_options(answer, course).collect { |o| o.is_a?(Array) ? [o[1].tr('_', ' ').to_s, o[0]] : o }
    if options.empty?
      content_tag :div, 'remove me', data: { remove_me: true }
    else
      select_tag(field_name, options_for_select(options), include_blank: (answer.question.multiple ? 'Select all that apply' : 'Select an option').to_s,
                                                          required: is_required_question?(answer),
                                                          multiple: answer.question.multiple,
                                                          class: 'chosen-container')
    end
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
      students = course.users.role('student')
      students.collect { |s| [s.id, s.username, contribution_link(s).to_s] }
    when 'Articles'
      course.articles.collect { |a| [a.id, a.title, "<a href='#{article_url(a)}' target='_blank'>#{a.title}</a>"] }
    when 'WikiEdu Staff'
      staff = course.users.role('wiki_ed_staff')
      staff.collect { |s| [s.id, s.username, contribution_link(s).to_s] }
    end
  end

  def can_administer?
    current_user && current_user.admin?
  end

  def question_type(answer)
    question_type_to_string(answer.question)
  end

  def question_type_to_string(question)
    question.type.to_s.split('::').last.downcase
  end

  def is_required_question?(answer)
    answer.question.validation_rules[:presence].to_i == 1
  end

  def is_grouped_question(answer)
    if answer.nil? || answer.question.nil?
      false
    else
      answer.question.validation_rules[:grouped].to_i == 1
    end
  end

  def grouped_question(answer)
    answer.question.validation_rules[:grouped_question]
  end

  def has_follow_up_question(answer)
    answer.question.follow_up_question_text? && !answer.question.follow_up_question_text.empty?
  end

  def start_of_group(options = {})
    answers = options[:answers]
    index = options[:index]
    answer = answers[index]
    answer_group_question = answer.question.validation_rules[:grouped_question]
    previous_answer = answers[index - 1]
    previous_grouped_question = previous_answer.question.validation_rules[:grouped_question]
    if index == 0 && is_grouped_question(answer)
      return true
    elsif is_grouped_question(answer) && !is_grouped_question(previous_answer)
      return true
    elsif is_grouped_question(answer) && !previous_question_in_same_group(answer, previous_answer)
      return true
    else
      return false
    end
  end

  def previous_question_in_same_group(current, previous)
    current.question.validation_rules[:grouped_question] == previous.question.validation_rules[:grouped_question]
  end

  def next_question_in_same_group(current, next_question)
    return false if next_question.nil?
    current.question.validation_rules[:grouped_question] == next_question.question.validation_rules[:grouped_question]
  end

  def end_of_group(answer, answer_group_builder, index)
    total_questions = answer_group_builder.answers.length
    grouped = is_grouped_question(answer)
    is_last_question = grouped && index + 1 == total_questions
    next_question = answer_group_builder.answers[index + 1]
    next_is_same_group = next_question_in_same_group(answer, next_question)
    next_isnt_grouped = !next_question.nil? && next_question.question.validation_rules[:grouped].to_i != 1
    if !grouped
      return false
    elsif is_last_question
      return true
    elsif !next_is_same_group
      return true
    elsif next_isnt_grouped
      return true
    else
      false
    end
  end

  def question_group_locals(surveys_question_group, index, total, results = false)
    @question_group = surveys_question_group.rapidfire_question_group
    @answer_group_builder = Rapidfire::AnswerGroupBuilder.new(params: {},
                                                              user: current_user,
                                                              question_group: @question_group)
    return {
      question_group: @question_group,
      answer_group_builder: @answer_group_builder,
      question_group_index: index,
      surveys_question_group: surveys_question_group,
      total: total,
      results: results
    }
  end

  def question_conditional_string(question)
    return '' if question.nil?
    return question.conditionals
  end

  def has_course_data(question_form)
    !question_form.course_data_type.nil? && !question_form.course_data_type.empty?
  end

  def question_form_has_follow_up_question(question_form)
    !question_form.follow_up_question_text.nil? && !question_form.follow_up_question_text.empty?
  end

  def conditional_string(answer)
    if answer.question.conditionals?
      string = strip_tags(answer.question.conditionals).tr(' ', '_').tr("'", "\\'")
      "data-conditional-question=#{string}"
    end
  end

  def is_radio_type(answer)
    question_type(answer) == 'radio'
  end

  private

  def has_course_slug
    params.key?('course_slug')
  end

  def set_course
    @course = find_course_by_slug(params[:course_slug]) if has_course_slug
  end

  def has_course_questions
    !@question_group.questions.course_data_questions.empty?
  end

  def set_course_if_survey_has_course_questions
    course_questions = @surveys_question_groups.map do |sqg|
      sqg.question_group.questions.course_data_questions
    end
    if !course_questions.empty? && !has_course_slug
      @courses = Course.all
      render 'course_select'
    else
      set_course
    end
  end

  def set_course_if_course_questions
    if has_course_questions && !has_course_slug
      @courses = Course.all
      render 'course_select'
    else
      set_course
    end
  end

  def survey_notification_id(notification)
    return nil if notification == false || notification.nil?
    return notification.id
  end

  def survey_class_for_path(req, path)
    current_path_segments = req.path.split('/').reject(&:blank?)
    active_path = path.split('/').reject(&:blank?).last
    current_path_segments.last == active_path ? 'active' : nil
  end
end
