FactoryGirl.define do
  factory :user do
    id '4543197'
    wiki_id 'Ragesock'
  end

  factory :trained, class: User do
    id '319203'
    wiki_id 'Ragesoss'
  end

  factory :admin, class: User do
    id '1'
    wiki_id 'Ragesauce'
    permissions '1'
  end
end
