# frozen_string_literal: true

# Rubocop now wants us to remove instance methods from helpers. This is a good idea
# but will require a bit of refactoring. Find other instances of this disabling
# and fix all at once.

require 'sentimental'

module QuestionResultsHelper
  def question_results_data(question, answers, id_to_answer_groups, users)
    processed_answers = prepare_answers_data(question, answers, id_to_answer_groups, users)
    {
      type: question_type_to_string(question),
      question:,
      sentiment: question.track_sentiment ? question_answers_average_sentiment(processed_answers) : {}, # rubocop:disable Layout/LineLength
      answer_options: question.answer_options.split(Rapidfire.answers_delimiter),
      answers: parse_answers(answers),
      answers_data: check_question_type?(question) ? processed_answers : [],
      grouped_question: question.validation_rules[:grouped_question],
      follow_up_question_text: question.follow_up_question_text,
      follow_up_answers: follow_ups?(answers) ? follow_up_answers(processed_answers) : {}
    }.to_json
  end

  def prepare_answers_data(question, answers, id_to_answer_groups, users)
    if question.track_sentiment? || check_question_type?(question) || follow_ups?(answers)
      build_question_answer_data(question, answers, id_to_answer_groups, users)
    end
  end

  def check_question_type?(question)
    %w[Rapidfire::Questions::Text Rapidfire::Questions::Long].include?(question.type)
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

  # Builds answer data with user/course info, caching expensive course lookups
  def build_question_answer_data(question, answers, id_to_answer_groups, users)
    return [] unless answers

    answers.map do |answer|
      answer_group = id_to_answer_groups[answer.answer_group_id]
      user = users[answer_group.user_id]
      course = user.respond_to?(:survey_course) ? user.survey_course : nil
      {
        data: { id: answer.id, answer_text: answer.answer_text,
                follow_up_answer_text: answer.follow_up_answer_text },
        user:,
        course:,
        campaigns: course&.campaigns,
        tags: course&.tags,
        sentiment: calculate_sentiment(question, answer)
      }
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
    scores = answers.filter_map { |a| a[:sentiment][:score] }
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
      next unless answer_record[:follow_up_answer_text].present?
      follow_ups[answer_record[:id]] = answer_record[:follow_up_answer_text]
    end

    return follow_ups
  end
end
