# == Schema Information
#
# Table name: articles
#
#  id                       :integer          not null, primary key
#  title                    :string(255)
#  views                    :integer          default(0)
#  created_at               :datetime
#  updated_at               :datetime
#  character_sum            :integer          default(0)
#  revision_count           :integer          default(0)
#  views_updated_at         :date
#  namespace                :integer
#  rating                   :string(255)
#  rating_updated_at        :datetime
#  deleted                  :boolean          default(FALSE)
#  language                 :string(10)
#  average_views            :float(24)
#  average_views_updated_at :date
#

FactoryGirl.define do
  factory :article do
    title 'History of biology'
    namespace 0
    language 'en'
  end
end
