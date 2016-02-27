module Rapidfire
  module Questions
    class Select < Rapidfire::Question
      validates :answer_options, :presence => true

      def options
        answer_options.split(Rapidfire.answers_delimiter)
      end

      def validate_answer(answer)
        super(answer)

        if rules[:presence] == "1" || answer.answer_text.present?
          answer.validates_inclusion_of :answer_text, :in => options
        end
      end
    end
  end
end
