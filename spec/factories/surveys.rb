FactoryGirl.define do
  
  factory :survey, class: 'Survey' do
    name "My Survey"
    after(:create) do |survey|
      # Add QeustionGroups to Survey
      question_groups = []
      3.times do |i| 
        question_groups.push(create(:question_group, :name => "Question Group #{i}"))
      end
      survey.rapidfire_question_groups = question_groups
    end
  end
end
