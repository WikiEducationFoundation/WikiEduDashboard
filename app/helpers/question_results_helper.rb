module QuestionResultsHelper
  def question_results_data(question)
    {
      type: question_type_to_string(question),
      answers: question_answers(question),
      grouped_question: question.validation_rules[:question_question],
      follow_up_question: question.follow_up_question_text,
      follow_up_answers: question.answers.pluck(:follow_up_answer_text).compact
    }.to_json
  end

  def question_answers(question)
    question.answers.map do |a|
      course = a.course(@survey)
      cohorts = course.cohorts unless course.nil?
      tags = course.tags unless course.nil?
      {
        answer: a,
        user: a.user,
        course: course,
        cohorts: cohorts,
        tags: tags
      }
    end
  end
end
