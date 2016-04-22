require 'sentimental'

module QuestionResultsHelper
  def question_results_data(question)
    answers = question_answers(question)
    {
      type: question_type_to_string(question),
      sentiment: question_answers_average_sentiment(answers),
      answer_options: question.answer_options.split(Rapidfire.answers_delimiter),
      answers: parse_answers(question),
      answers_data: answers,
      grouped_question: question.validation_rules[:question_question],
      follow_up_question: question.follow_up_question_text,
      follow_up_answers: question.answers.pluck(:follow_up_answer_text).compact
    }.to_json
  end

  def parse_answers(question)
    answers = question.answers.pluck(:answer_text).compact
    answers.map { |a| a.split(Rapidfire.answers_delimiter) }.flatten
  end

  def question_answers(question)
    analyzer = Sentimental.new
    analyzer.load_defaults
    question.answers.map do |a|
      course = a.course(@survey)
      cohorts = course.cohorts unless course.nil?
      tags = course.tags unless course.nil?
      {
        data: a,
        sentiment: {
          label: analyzer.sentiment(a.answer_text),
          score: analyzer.score(a.answer_text)
        },
        user: a.user,
        course: course,
        cohorts: cohorts,
        tags: tags
      }
    end
  end

  def question_answers_average_sentiment(answers)
    scores = answers.collect { |a| a[:sentiment][:score] }
    average = 0
    average = scores.sum / scores.length unless scores.empty?
    label = 'negative'
    label = 'positive' if average > 0
    label = 'neutral' if average == 0
    {
      average: average,
      label: label
    }
  end

end
