FactoryGirl.define do
  factory :answer_group, :class => "Rapidfire::AnswerGroup" do
    question_group  { FactoryGirl.create(:question_group) }
  end
end
