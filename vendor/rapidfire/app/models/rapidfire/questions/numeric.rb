module Rapidfire
  module Questions
    class Numeric < Rapidfire::Question
      def validate_answer(answer)
        super(answer)

        if rules[:presence] == "1" || answer.answer_text.present?
          gt_or_lt = {}
          if rules[:greater_than_or_equal_to].present?
            gt_or_lt[:greater_than_or_equal_to] = rules[:greater_than_or_equal_to].to_i
          end
          if rules[:less_than_or_equal_to].present?
            gt_or_lt[:less_than_or_equal_to] = rules[:less_than_or_equal_to].to_i
          end

          answer.validates_numericality_of :answer_text, gt_or_lt
        end
      end
    end
  end
end
