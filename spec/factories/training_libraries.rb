# frozen_string_literal: true
# == Schema Information
#
# Table name: training_libraries
#
#  id                 :bigint           not null, primary key
#  name               :string(255)
#  wiki_page          :string(255)
#  slug               :string(255)
#  introduction       :text(65535)
#  categories         :text(16777215)
#  translations       :text(16777215)
#  exclude_from_index :boolean          default(FALSE)
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#

FactoryBot.define do
  factory :training_library do
  end
end
