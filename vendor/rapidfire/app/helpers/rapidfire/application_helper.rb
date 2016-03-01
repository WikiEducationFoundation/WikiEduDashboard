module Rapidfire
  module ApplicationHelper

    def question_type(answer)
      answer.question.type.to_s.split("::").last.downcase
    end

    def render_answer_form_helper(answer, form)
      partial = question_type(answer)
      render partial: "rapidfire/answers/#{partial}", locals: { f: form, answer: answer }
    end

    def checkbox_checked?(answer, option)
      answers_delimiter = Rapidfire.answers_delimiter
      answers = answer.answer_text.to_s.split(answers_delimiter)
      answers.include?(option)
    end

    def question_text(question)
      if question.validation_rules[:presence]
        "#{question.question_text} <span>*required</span>"
      else
        "#{question.question_text}"
      end
    end
  end
end
