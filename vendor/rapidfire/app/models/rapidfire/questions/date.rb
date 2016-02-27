module Rapidfire
  module Questions
    class Date < Rapidfire::Question
      def validate_answer(answer)
        super(answer)

        if rules[:presence] == "1" || answer.answer_text.present?
          begin  ::Date.parse(answer.answer_text.to_s)
          rescue ArgumentError => e
            answer.errors.add(:answer_text, :invalid)
          end
        end
      end
    end
  end
end
