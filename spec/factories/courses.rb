FactoryGirl.define do
  factory :course do
    start '2015-01-01'.to_date
    title 'Underwater basket-weaving'
    listed true
    slug 'slug'
  end
end
