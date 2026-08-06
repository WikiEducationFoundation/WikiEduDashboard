# frozen_string_literal: true

module ClaimVerification
  # One step of the fact-verification exercise form: a heading, optional
  # instructions, and the questions asked under it. Declared in
  # config/claim_verification_exercise.yml, which also documents how the copy is
  # looked up from the step's id.
  #
  # `number` is assigned by ExerciseForm rather than written into the copy, so
  # reordering the steps renumbers them; an unnumbered step (`heading: false`)
  # has no number and no heading, like the closing comments field.
  FormStep = Data.define(:id, :number, :questions, :visible_when) do
    def self.from_config(config, number:)
      new(id: config.fetch('id'), number:,
          questions: (config['questions'] || []).map { |q| FormQuestion.from_config(q) },
          visible_when: config['visible_when'] || {})
    end

    def numbered?
      !number.nil?
    end

    # Whether the step is shown at all, given the answers so far.
    def applicable?(answers)
      visible_when.all? { |question_id, values| values.include?(answers[question_id]) }
    end

    # "Step 4: Find the source" — the number is composed in, not part of the copy.
    # The format string is shared with the two steps that come before the form
    # (see app/assets/javascripts/components/claim_verification_exercise/steps.js),
    # so every step of the exercise reads as one sequence.
    def heading
      return unless numbered?
      I18n.t('claim_verification.step_heading',
             number:, name: I18n.t("claim_verification.form.step_#{id}"))
    end

    # Steps may explain themselves before asking; most do, the comments step
    # doesn't. `default: nil` rather than I18n.exists?, so a locale missing this
    # string still falls back to English instead of dropping the instructions.
    def instructions
      I18n.t("claim_verification.form.#{id}_instructions", default: nil).presence
    end
  end
end
