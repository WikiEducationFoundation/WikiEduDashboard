# frozen_string_literal: true

# Rubocop now wants us to remove instance methods from helpers. This is a good idea
# but will require a bit of refactoring. Find other instances of this disabling
# and fix all at once.

require 'sentimental'

module QuestionResultsHelper
  def question_results_data(question, answers, id_to_answer_groups, users, survey_user_cache)
    processed_answers = prepare_answers_data(question, answers, id_to_answer_groups, users,
                                              survey_user_cache)
    {
      type: question_type_to_string(question),
      question:,
      sentiment: question.track_sentiment ? question_answers_average_sentiment(processed_answers) : nil, # rubocop:disable Layout/LineLength
      answer_options: question.answer_options.split(Rapidfire.answers_delimiter),
      answers: parse_answers(answers),
      answers_data: question.type.eql?('Rapidfire::Questions::Text') ? processed_answers : nil,
      grouped_question: question.validation_rules[:grouped_question],
      follow_up_question_text: question.follow_up_question_text,
      follow_up_answers: follow_ups?(answers) ? follow_up_answers(processed_answers) : {}
    }.to_json
  end

  def prepare_answers_data(question, answers, id_to_answer_groups, users, survey_user_cache)
    if question.track_sentiment? || question.type.eql?('Rapidfire::Questions::Text') || follow_ups?(answers) # rubocop:disable Layout/LineLength
      question_answers(question, answers, id_to_answer_groups, users, survey_user_cache)
    end
  end

  def follow_ups?(answers)
    answers&.any? { |answer| answer.follow_up_answer_text.present? } || false
  end

  def parse_answers(answers)
    return [] if answers.nil?

    answers
      .filter_map(&:answer_text)
      .flat_map { |text| text.to_s.split(Rapidfire.answers_delimiter) }
      .reject(&:blank?)
  end

  def question_answers(question, answers, id_to_answer_groups, users, survey_user_cache)
    answers&.map do |answer|
      user_id = id_to_answer_groups[answer.answer_group_id].user_id
      user = users[user_id]
      if survey_user_cache.key?(user_id)
        course = survey_user_cache[user_id]
      else
        course = answer.course(@survey.id, user)
        survey_user_cache[user_id] = course
      end
      { data: answer, user:, course:, campaigns: course&.campaigns,
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

  def respondents(question, question_answers_count)
    total = question_answers_count[question.id] || 0
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
    answers&.each do |answer|
      answer_record = answer[:data]
      next unless answer_record.follow_up_answer_text.present?
      follow_ups[answer_record.id] = answer_record.follow_up_answer_text
    end

    return follow_ups
  end
end
