# frozen_string_literal: true

# == Schema Information
#
# Table name: articles
#
#  id                       :integer          not null, primary key
#  title                    :string(255)
#  updated_at               :datetime
#  created_at               :datetime
#  views_updated_at         :date
#  namespace                :integer
#  rating                   :string(255)
#  rating_updated_at        :datetime
#  deleted                  :boolean          default(FALSE)
#  language                 :string(10)
#  average_views            :float(24)
#  average_views_updated_at :date
#  wiki_id                  :integer
#  mw_page_id               :integer
#

FactoryBot.define do
  factory :article do
    title 'History_of_biology'
    namespace 0
    language 'en'
    wiki_id 1
    sequence(:mw_page_id)
  end
end
