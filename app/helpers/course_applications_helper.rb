# frozen_string_literal: true

# Layout for the Scholars & Scientists application form
# (course_applications/_form).
module CourseApplicationsHelper
  # The form's questions, in order, as [:question, question] and
  # [:matrix, title, questions] entries. A matrix is a run of consecutive
  # multiple-choice questions marked "grouped" in the question editor with the
  # same grouping text and the same options, which the form shows as one table
  # (as surveys do), so a scale of statements isn't a long column of choices.
  def application_question_layout(questions)
    questions.chunk_while { |a, b| same_matrix?(a, b) }.flat_map do |run|
      next [[:matrix, run.first.rules[:grouped_question].presence, run]] if run.length > 1

      [[:question, run.first]]
    end
  end

  # An answer's error messages. A missing answer gets the Dashboard's own
  # "required" message rather than Rails' "Answer text can't be blank"; other
  # errors keep Rails' text.
  def application_answer_errors(answer)
    return [] unless answer

    answer.errors.map do |error|
      error.type == :blank ? t('application.field_required') : error.full_message
    end.uniq
  end

  private

  def same_matrix?(first, second)
    [first, second].all? { |q| matrix_question?(q) } &&
      first.rules[:grouped_question] == second.rules[:grouped_question] &&
      first.options == second.options
  end

  def matrix_question?(question)
    question.instance_of?(Rapidfire::Questions::Radio) && question.rules[:grouped].to_i == 1
  end
end
