# frozen_string_literal: true

# Rubocop now wants us to remove instance methods from helpers. This is a good idea
# but will require a bit of refactoring. Find other instances of this disabling
# and fix all at once.
# rubocop:disable Rails/HelperInstanceVariable

require 'sentimental'

module QuestionResultsHelper
  def question_results_data(question, survey_user_cache)
    answers = question_answers(question, survey_user_cache)
    {
      type: question_type_to_string(question),
      question:,
      sentiment: question.track_sentiment ? question_answers_average_sentiment(answers) : nil,
      answer_options: question.answer_options.split(Rapidfire.answers_delimiter),
      answers: parse_answers(question),
      answers_data: answers,
      grouped_question: question.validation_rules[:question_question],
      follow_up_question_text: question.follow_up_question_text,
      follow_up_answers: follow_up_answers(answers)
    }.to_json
  end

  def parse_answers(question)
    answers = question.answers.pluck(:answer_text).compact
    answers.map { |a| a.split(Rapidfire.answers_delimiter) }.flatten
  end

  def question_answers(question, survey_user_cache)
    question.answers.map do |answer|
      if survey_user_cache.key?(answer.user.id)
        course = survey_user_cache[answer.user.id]
      else
        course = answer.course(@survey.id, answer.user)
        survey_user_cache[answer.user.id] = course
      end
      { data: answer, user: answer.user, course:, campaigns: course&.campaigns,
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
      label:
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

  def follow_up_answers(answers)
    follow_ups = {}
    answers.each do |answer|
      answer_record = answer[:data]
      next unless answer_record.follow_up_answer_text.present?
      follow_ups[answer_record.id] = answer_record.follow_up_answer_text
    end

    return follow_ups
  end
end
# rubocop:enable Rails/HelperInstanceVariable
