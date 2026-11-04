# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/rapidfire_conditionals"

# Saves one person's application to a Scholars & Scientists course: the
# CourseApplication and one Rapidfire answer group per question group on the
# course's form, in a single all-or-nothing save. Questions the applicant was
# not shown (their conditionals unmet) get no answer, so their requirements do
# not apply. Callers check that the form is accepting applications and that the
# user may apply.
class SubmitCourseApplication
  attr_reader :application

  # `answers` maps question id (as a string) to { answer_text:,
  # follow_up_answer_text: }, as the apply form submits them. A checkbox
  # question's answer_text is an array.
  def initialize(course:, user:, answers:)
    @course = course
    @user = user
    @answers = answers.to_h.with_indifferent_access
    @application = CourseApplication.new(course:, user:)
    perform
  end

  def success?
    @application.persisted?
  end

  # The submitted answers, with any validation errors, keyed by question id,
  # for re-rendering the form.
  def answers_by_question_id
    @application.answer_groups.flat_map(&:answers).index_by(&:question_id)
  end

  private

  def perform
    build_answer_groups
    @application.save
  rescue ActiveRecord::RecordNotUnique
    # A second submission from the same person raced this one and won.
    @application.errors.add(:user_id, :taken)
  end

  def build_answer_groups
    question_groups.each do |group|
      answer_group = @application.answer_groups.build(question_group: group, user: @user,
                                                      course_id: @course.id)
      group.questions.each { |question| build_answer(answer_group, question) }
    end
  end

  def build_answer(answer_group, question)
    # Text questions are display-only.
    return if question.is_a?(Rapidfire::Questions::Text)
    return unless visibility.visible?(question)

    submitted = @answers[question.id.to_s] || {}
    answer_group.answers.build(question:,
                               answer_text: answer_text(submitted[:answer_text]),
                               follow_up_answer_text: submitted[:follow_up_answer_text])
  end

  # Checkbox answers are stored as one string, as Rapidfire's survey
  # submissions store them.
  def answer_text(submitted)
    return submitted unless submitted.is_a?(Array)
    submitted.map(&:strip).compact_blank.join(Rapidfire.answers_delimiter)
  end

  def question_groups
    @question_groups ||= @course.course_application_form.question_groups
  end

  def visibility
    @visibility ||= begin
      questions = question_groups.flat_map { |group| group.questions.to_a }
      answer_texts = @answers.to_h { |id, submitted| [id, submitted&.dig(:answer_text)] }
      RapidfireConditionals.new(questions, answer_texts)
    end
  end
end
