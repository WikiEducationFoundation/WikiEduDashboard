# == Schema Information
#
# Table name: course_wiki_namespaces
#
#  id               :bigint           not null, primary key
#  namespace        :integer
#  courses_wikis_id :bigint
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
FactoryBot.define do
  factory :course_wiki_namespaces do
    namespace { 1 }
    courses_wikis { nil }
  end
end
