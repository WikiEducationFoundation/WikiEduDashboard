FactoryGirl.define do
  factory :answer, :class => "Rapidfire::Answer" do
    answer_group  { FactoryGirl.create(:answer_group) }
    question      { FactoryGirl.create(:q_long)       }
    answer_text   "hello world"
  end
end
