# frozen_string_literal: true

# Presenter for question / answer fields in a survey
class RapidfireQuestionPresenter
  def initialize(answer, index:, answer_group_builder:, is_results_view:)
    @answer = answer # represents an unsaved blank answer for a Rapidfire::Question
    @index = index # question index within a Rapidfire::QuestionGroup
    @answer_group_builder = answer_group_builder
    @answers_in_group = @answer_group_builder.answers
    @is_results_view = is_results_view
  end

  def question_type
    question_type_to_string(@answer.question)
  end

  # The 'text' question type represents a card of text, not an actual question.
  def text_only?
    question_type == 'text'
  end

  def results_view?
    @is_results_view
  end

  def start_of_group?
    return false unless grouped_question?
    return true if @index.zero?

    previous_answer = @answers_in_group[@index - 1]
    return true unless answer_is_for_grouped_question?(previous_answer)
    return true unless questions_in_same_group?(@answer, previous_answer)
    return false
  end

  def end_of_group?
    return true unless grouped_question?

    total_questions = @answers_in_group.length
    is_last_question = (@index + 1 == total_questions)
    return true if is_last_question

    next_question = @answers_in_group[@index + 1]
    return true unless questions_in_same_group?(@answer, next_question)

    return false
  end

  def grouped_question?
    answer_is_for_grouped_question?(@answer)
  end

  def required_class
    required? ? ' required' : ''
  end

  def start_of_radio_matrix?
    !results_view? && start_of_group? && radio_type?
  end

  def follow_up_question?
    @answer.question.follow_up_question_text.present?
  end

  private

  def required?
    @answer.question.validation_rules[:presence].to_i == 1
  end

  def radio_type?
    question_type == 'radio'
  end

  def question_type_to_string(question)
    question.type.to_s.split('::').last.downcase
  end

  def answer_is_for_grouped_question?(answer)
    return false if answer.nil? || answer.question.nil?
    answer.question.validation_rules[:grouped].to_i == 1
  end

  def questions_in_same_group?(first, second)
    return false if first.nil? || second.nil?
    grouped_question(first) == grouped_question(second)
  end

  def grouped_question(answer)
    answer.question.validation_rules[:grouped_question]
  end
end
