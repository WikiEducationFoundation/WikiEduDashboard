# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/claim_verification/answer_gate"

module ClaimVerification
  # One question of the fact-verification exercise form, as declared in
  # config/claim_verification_exercise.yml. Its copy is looked up from the
  # locales by convention from its id (see that file), so a question is fully
  # described by its id, its type, and the answers it accepts.
  #
  # - id: also the key this question's answer is stored under
  # - type: 'choice' (one of `options`) or 'text' (free response)
  # - options: the accepted answers, for a choice question
  # - required: submission is blocked until this is answered
  # - visible_when: { other question id => [answers] | true }; asked only when
  #   that earlier answer is one of those, or any answer at all (see AnswerGate)
  FormQuestion = Data.define(:id, :type, :options, :required, :visible_when) do
    def self.from_config(config)
      new(id: config.fetch('id'), type: config.fetch('type'),
          options: config['options'] || [], required: config['required'] || false,
          visible_when: config['visible_when'] || {})
    end

    def choice?
      type == 'choice'
    end

    # Whether this question is asked at all, given the answers so far. A
    # question with no `visible_when` is always asked.
    def applicable?(answers)
      AnswerGate.open?(visible_when, answers)
    end

    def label
      I18n.t("claim_verification.form.#{choice? ? "#{id}_question" : "#{id}_label"}")
    end

    # The choice options as value/label pairs, in the order the form offers them.
    def option_labels
      options.map do |value|
        { value:, label: I18n.t("claim_verification.form.#{id}_options.#{value}") }
      end
    end
  end
end
