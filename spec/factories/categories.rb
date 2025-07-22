# frozen_string_literal: true
# == Schema Information
#
# Table name: categories
#
#  id             :bigint           not null, primary key
#  wiki_id        :integer
#  article_titles :text(16777215)
#  name           :string(255)
#  depth          :integer          default(0)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  source         :string(255)      default("category")
#

FactoryBot.define do
  factory :category do
    name { 'Foo' }
    wiki_id { 1 }
  end
end
