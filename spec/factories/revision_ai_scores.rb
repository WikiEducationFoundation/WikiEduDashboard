# frozen_string_literal: true
# == Schema Information
#
# Table name: revision_ai_scores
#
#  id                :bigint           not null, primary key
#  revision_id       :integer
#  wiki_id           :integer
#  course_id         :integer
#  user_id           :integer
#  article_id        :integer
#  revision_datetime :datetime
#  avg_ai_likelihood :float(24)
#  max_ai_likelihood :float(24)
#  details           :text(65535)
#  check_type        :string(255)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  url               :string(255)
#  check_origin      :string(255)
#  origin_user_id    :integer
#
FactoryBot.define do
  factory :revision_ai_score do
  end
end
