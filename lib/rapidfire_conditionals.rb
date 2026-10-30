# frozen_string_literal: true

# Decides which Rapidfire questions a respondent was shown, given their answers,
# by evaluating each question's `conditionals` string the way the survey
# front end does (Survey.js, SurveyUtils.parseConditionalString). Used where
# answers are validated on the server — a required question the respondent
# never saw must not be required.
#
# A conditional is "<question id>|<operator>|<value>[|multi]":
#   - "*presence": shown once the parent question has any answer.
#   - "<", "<=", ">", ">=": numeric comparison with the parent's answer.
#   - anything else ("="): shown when the parent's answer, or any of its
#     checked options, matches the value. The admin UI stores the value with
#     spaces as underscores and quotes as HTML entities, so both sides are
#     normalized before comparing.
#
# A question whose parent is itself hidden is hidden too.
class RapidfireConditionals
  COMPARISONS = {
    '<' => :<, '<=' => :<=, '>' => :>, '>=' => :>=
  }.freeze

  # `answers` maps question id to the submitted answer: a string, or an array
  # of strings for a checkbox question.
  def initialize(questions, answers)
    @questions_by_id = questions.index_by(&:id)
    @answers = answers.transform_keys(&:to_i)
    @visible = {}
  end

  def visible?(question)
    return @visible[question.id] if @visible.key?(question.id)
    @visible[question.id] = compute_visibility(question)
  end

  private

  def compute_visibility(question)
    return true if question.conditionals.blank?

    parent_id, operator, value = question.conditionals.split('|')
    parent = @questions_by_id[parent_id.to_i]
    # A condition on a question outside this set can't be met here.
    return false if parent.nil? || !visible?(parent)

    condition_met?(Array(@answers[parent.id]).compact_blank, operator, value)
  end

  def condition_met?(answers, operator, value)
    return answers.any? if operator == '*presence'
    return compare(answers.first, operator, value) if COMPARISONS.key?(operator)

    answers.any? { |answer| normalize(answer) == normalize(value) }
  end

  def compare(answer, operator, value)
    return false unless numeric?(answer) && numeric?(value)
    answer.to_i.public_send(COMPARISONS[operator], value.to_i)
  end

  def numeric?(string)
    string.to_s.strip.match?(/\A-?\d+/)
  end

  def normalize(string)
    CGI.unescapeHTML(ActionController::Base.helpers.strip_tags(string.to_s)).strip.tr(' ', '_')
  end
end
