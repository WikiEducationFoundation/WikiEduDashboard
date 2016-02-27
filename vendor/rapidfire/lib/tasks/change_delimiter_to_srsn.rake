desc 'Earlier delimiter used to be comma(,), but for #19, delimter is changed to \r\n'
namespace :rapidfire do
  task change_delimiter_from_comma_to_srsn: :environment do
    Rapidfire::Question.transaction do
      Rapidfire::Question.all.each do |question|
        if question.is_a?(Rapidfire::Questions::Checkbox) ||
            question.is_a?(Rapidfire::Questions::Select)

          new_answer_options = question.answer_options.split(',')
            .join(Rapidfire.answers_delimiter)
          question.update_attributes!(answer_options: new_answer_options)
        end
      end
    end
  end
end
