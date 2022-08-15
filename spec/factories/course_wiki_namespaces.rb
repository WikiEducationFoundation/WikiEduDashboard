FactoryBot.define do
  factory :course_wiki_namespaces do
    namespace { 1 }
    courses_wikis { nil }
  end
end
