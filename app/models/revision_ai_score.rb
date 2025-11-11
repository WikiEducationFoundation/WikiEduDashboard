# frozen_string_literal: true
# == Schema Information
#
# Table name: revision_ai_scores
#
#  id                :bigint           not null, primary key
#  revision_id       :integer          not null
#  wiki_id           :integer          not null
#  course_id         :integer          not null
#  user_id           :integer          not null
#  article_id        :integer
#  date              :datetime
#  avg_ai_likelihood :float(24)
#  max_ai_likelihood :float(24)
#  details           :text(65535)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
class RevisionAiScore < ApplicationRecord
end
