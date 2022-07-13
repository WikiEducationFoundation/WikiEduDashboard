FactoryBot.define do
  factory :courses_namespaces do
    namespace { 1 }
    courses_wikis { nil }
  end
end
