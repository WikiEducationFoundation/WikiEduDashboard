# frozen_string_literal: true
# == Schema Information
#
# Table name: training_slides
#
#  id           :bigint           not null, primary key
#  title        :string(255)
#  title_prefix :string(255)
#  summary      :string(255)
#  button_text  :string(255)
#  wiki_page    :string(255)
#  assessment   :text(16777215)
#  content      :text(65535)
#  translations :text(4294967295)
#  slug         :string(255)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

FactoryBot.define do
  factory :training_slide do
    title { 'How to create a slide' }
    slug { 'how-to-create-a-slide' }
  end
end
