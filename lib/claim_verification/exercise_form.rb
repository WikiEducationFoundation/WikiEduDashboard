# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/claim_verification/form_step"
require_dependency "#{Rails.root}/lib/claim_verification/form_question"

module ClaimVerification
  # The fact-verification exercise's form, as declared in
  # config/claim_verification_exercise.yml: the steps it asks, the questions
  # under them, and the answers each accepts.
  #
  # This is the single definition of the exercise's shape. The model stores
  # answers as a hash keyed by question id, the controller permits whatever keys
  # it names, and the SPA renders both the form and the submitted-answers summary
  # from it — so a change to the exercise is a change to that file alone.
  class ExerciseForm
    CONFIG_PATH = "#{Rails.root}/config/claim_verification_exercise.yml"

    def self.definition
      # Reloaded every time in development so editing the exercise doesn't need a
      # server restart; read once in production.
      return YAML.load_file(CONFIG_PATH) unless Rails.env.production?
      @definition ||= YAML.load_file(CONFIG_PATH)
    end

    def steps
      @steps ||= build_steps
    end

    def questions
      steps.flat_map(&:questions)
    end

    # Every question id, whether or not it currently applies — what the
    # controller permits from the client.
    def answer_keys
      questions.map(&:id)
    end

    # The submitted answers, less anything the exercise didn't actually ask:
    # unknown keys, and answers to questions hidden by the path the student took
    # (see FormQuestion#applicable?). Storing only what was asked keeps an
    # abandoned branch from leaving stale answers behind.
    def applicable_answers(submitted)
      answers = submitted.to_h.stringify_keys
      applicable_questions(answers).to_h { |question| [question.id, answers[question.id]] }
                                   .compact_blank
    end

    # Questions actually asked given these answers, in form order.
    def applicable_questions(answers)
      steps.select { |step| step.applicable?(answers) }
           .flat_map(&:questions)
           .select { |question| question.applicable?(answers) }
    end

    # Why these answers aren't a valid submission: a required question left
    # unanswered, or a choice answered with something the question doesn't take
    # (an option it offers, or a retired one a response was recorded with).
    # Developer-facing — the client blocks invalid submissions itself.
    def errors_in(answers)
      applicable_questions(answers.to_h.stringify_keys).filter_map do |question|
        error_for(question, answers.to_h.stringify_keys[question.id])
      end
    end

    private

    def error_for(question, answer)
      return "#{question.id} is required" if question.required && answer.blank?
      return if answer.blank? || !question.choice?
      "#{answer} is not an accepted answer for #{question.id}" unless question.accepts?(answer)
    end

    # Numbers are assigned here rather than written into the copy, counting only
    # the steps that show a heading, so reordering the config renumbers them.
    def build_steps
      number = self.class.definition['first_step_number']
      self.class.definition['steps'].map do |config|
        numbered = config['heading'] != false
        step = FormStep.from_config(config, number: numbered ? number : nil)
        number += 1 if numbered
        step
      end
    end
  end
end
