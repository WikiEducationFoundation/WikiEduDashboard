module SurveysHelper
  
  def survey_page(request)
    root_path = request.path.split('/')[1] 
    ["surveys", "rapidfire"].include? rootpath
  end

  def render_answer_form_helper(answer, form)
    partial = answer.question.type.to_s.split("::").last.downcase
    render partial: "rapidfire/answers/#{partial}", locals: { f: form, answer: answer, course: @course }
  end

  def survey_select(f, answer, course)
    options = answer_options(answer, course).collect { |o| o.is_a?(Array) ? [ "#{o[1].tr('_', ' ')}", o[0]] : o }
    select_tag(:answer_text, options_for_select(options), { 
          :include_blank => "#{answer.question.multiple ? 'Select all that apply' : 'Select an option'}",
          :required => is_required_question?(answer), 
          :multiple => answer.question.multiple, 
          :data => {:chosen_select => true}
        })
  end

  def answer_options(answer, course)
    question = answer.question
    if question.options.length > 0
      question.options
    elsif course != nil 
      course_answer_options(question.course_data_type, course)
    end
  end

  def course_answer_options(type, course)
    case type
    when COURSE_DATA_ANSWER_TYPES[0] #Students
      students = course.users.role('student')
      students.collect { |s| [s.id, s.username, "#{contribution_link(s)}"]}
    when COURSE_DATA_ANSWER_TYPES[1] #Articles
      course.articles.collect { |a| [a.id, a.title, "<a href='#{article_url(a)}' target='_blank'>#{a.title}</a>"]}
    when COURSE_DATA_ANSWER_TYPES[2] #WikiEdu Staff
      staff = course.users.role('wiki_ed_staff')
      staff.collect { |s| [s.id, s.username, "#{contribution_link(s)}"]}
    end
  end

  def can_administer?
    current_user && current_user.admin?
  end

  def question_type(answer)
    answer.question.type.to_s.split("::").last.downcase
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
    last_answer = answers[index - 1]
    if index == 0 && is_grouped_question(answer)
      return true
    elsif is_grouped_question(answer) && !is_grouped_question(last_answer)
      return true
    else
      return false
    end
  end

  def next_question_is_start_of_group(index, answer, answers)
    !is_grouped_question(answer) && is_grouped_question(answers[index + 1])
  end

  def question_group_locals(surveys_question_group, index, total)
    @question_group = surveys_question_group.rapidfire_question_group
    @answer_group_builder = Rapidfire::AnswerGroupBuilder.new({
      params: {},
      user: current_user,
      question_group: @question_group
    })
    return {
      question_group: @question_group,
      answer_group_builder: @answer_group_builder,
      question_group_index: index,
      surveys_question_group: surveys_question_group,
      total: total
    }
  end

  def question_conditional_string(question)
    return "" if question.nil?
    return question.conditionals
  end

  def has_course_data(question_form)
    question_form.course_data_type != nil && !question_form.course_data_type.empty?
  end

  def question_form_has_follow_up_question(question_form)
    !question_form.follow_up_question_text.nil? && !question_form.follow_up_question_text.empty?
  end

  def is_matrix_question(question_form)
    !question_form.follow_up_question_text.nil? && !question_form.follow_up_question_text.empty?
  end
  
end
