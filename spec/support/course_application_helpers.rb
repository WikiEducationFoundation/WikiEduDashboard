# frozen_string_literal: true

# Every Scholars & Scientists application form asks the built-in questions
# (CourseApplicationDefaultQuestions), many of them required, so specs that
# submit applications include answers to them.
module CourseApplicationHelpers
  # Answers to every built-in question still asked, keyed by question id as the
  # apply form submits them. Pass `overrides` by question key.
  def built_in_application_answers(**overrides)
    CourseApplicationDefaultQuestions.entries.reject(&:retired).to_h do |entry|
      question = entry.question
      text = overrides.fetch(entry.key.to_sym) { sample_application_answer(question) }
      [question.id.to_s, { answer_text: text }]
    end
  end

  # In a feature spec, answers every built-in question on the apply form, the
  # way built_in_application_answers does.
  def fill_in_built_in_application_questions
    built_in_application_answers.each do |id, answer|
      question = CourseApplicationDefaultQuestions.question(id.to_i)
      next if question.conditionals.present?

      within("#question_#{id}") do
        case question
        when Rapidfire::Questions::Radio, Rapidfire::Questions::Checkbox
          Array(answer[:answer_text]).each do |option|
            find('label', text: option, exact_text: true).click
          end
        else
          find("#answer_#{id}").fill_in(with: answer[:answer_text])
        end
      end
    end
  end

  private

  def sample_application_answer(question)
    case question
    when Rapidfire::Questions::Checkbox then [question.options.first]
    when Rapidfire::Questions::Radio then question.options.first
    else "Sample answer to #{question.id}"
    end
  end
end

RSpec.configure do |config|
  config.include CourseApplicationHelpers
end
