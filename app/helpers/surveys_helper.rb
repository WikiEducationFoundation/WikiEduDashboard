module SurveysHelper
  
  def survey_page(request)
    root_path = request.path.split('/')[1] 
    ["surveys", "rapidfire"].include? rootpath
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
    if answer.nil?
      false
    else
      answer.question.validation_rules[:grouped].to_i == 1
    end
  end

  def grouped_question(answer)
    answer.question.validation_rules[:grouped_question]
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

  def question_group_locals(question_group)
    
    @question_group = question_group
    @answer_group_builder = Rapidfire::AnswerGroupBuilder.new({
      params: {},
      user: current_user, 
      question_group: question_group
    })
    return {
      question_group: @question_group,
      answer_group_builder: @answer_group_builder
    }
  end
  
end
