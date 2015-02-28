FactoryGirl.define do
  # article that exists
  factory :assignment do
    id 1
    created_at "2015-02-18 18:02:50"
    updated_at "2015-02-18 18:03:01"
    user_id 23682032
    course_id 481
    article_id 12488499
    article_title "Siderocalin"
  end

  # article that does not exist
  factory :redlink, class: Assignment do
    id 2
    created_at "2015-02-18 18:02:50"
    updated_at "2015-02-18 18:02:50"
    user_id 22497786
    course_id 481
    article_id nil
    article_title "Faecal calprotectin"
  end

end
