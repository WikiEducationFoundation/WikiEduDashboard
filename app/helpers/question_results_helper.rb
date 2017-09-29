# frozen_string_literal: true

require 'sentimental'

module QuestionResultsHelper
  def question_results_data(question)
    answers = question_answers(question)
    {
      type: question_type_to_string(question),
      question: question,
      sentiment: question.track_sentiment ? question_answers_average_sentiment(answers) : nil,
      answer_options: question.answer_options.split(Rapidfire.answers_delimiter),
      answers: parse_answers(question),
      answers_data: answers,
      grouped_question: question.validation_rules[:question_question],
      follow_up_question_text: question.follow_up_question_text,
      follow_up_answers: question.answers.pluck(:follow_up_answer_text).compact
    }.to_json
  end

  def parse_answers(question)
    answers = question.answers.pluck(:answer_text).compact
    answers.map { |a| a.split(Rapidfire.answers_delimiter) }.flatten
  end

  def question_answers(question)
    question.answers.map do |answer|
      course = answer.course(@survey.id)
      { data: answer, user: answer.user, course: course, campaigns: course&.campaigns,
        tags: course&.tags, sentiment: calculate_sentiment(question, answer) }
    end
  end

  def calculate_sentiment(question, answer)
    return {} unless question.track_sentiment
    analyzer = Sentimental.new
    analyzer.load_defaults
    {
      label: analyzer.sentiment(answer.answer_text),
      score: analyzer.score(answer.answer_text).round(2)
    }
  end

  def question_answers_average_sentiment(answers)
    scores = answers.collect { |a| a[:sentiment][:score] }
    average = 0
    average = scores.sum / scores.length unless scores.empty?
    label = 'negative'
    label = 'positive' if average.positive?
    label = 'neutral' if average.zero?
    {
      average: average.round(2),
      label: label
    }
  end

  def respondents(question)
    total = question.answers.count
    label = 'Respondents'
    label.pluralize if total > 1
    "#{total} #{label}"
  end

  ########################################
  # Helper method used only in this file #
  ########################################

  def question_type_to_string(question)
    question.type.to_s.split('::').last.downcase
  end
end
