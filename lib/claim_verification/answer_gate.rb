# frozen_string_literal: true

module ClaimVerification
  # Whether a `visible_when` gate is open, given the answers so far. Steps and
  # questions of the fact-verification exercise gate identically, so both ask
  # here, and the client applies the same rules (see formDefinition.js).
  #
  # A gate maps another question's id to what opens it: a list of accepted
  # answers, or `true` for any answer at all — which is how the closing comments
  # step waits until the student has said whether they got the source without
  # having to name every way they might have answered that. A gate with no
  # entries is always open.
  module AnswerGate
    def self.open?(visible_when, answers)
      visible_when.all? do |question_id, opens_on|
        answer = answers[question_id]
        opens_on == true ? answer.present? : opens_on.include?(answer)
      end
    end
  end
end
