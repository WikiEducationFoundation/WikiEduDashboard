# frozen_string_literal: true
# == Schema Information
#
# Table name: article_course_timeslices
#
#  id                :bigint           not null, primary key
#  article_course_id :integer          not null
#  start             :datetime
#  end               :datetime
#  last_mw_rev_id    :integer
#  character_sum     :integer          default(0)
#  references_count  :integer          default(0)
#  user_ids          :text(65535)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

require 'rails_helper'
require "#{Rails.root}/lib/importers/article_importer"
require "#{Rails.root}/lib/articles_courses_cleaner"

describe ArticleCourseTimeslice, type: :model do
  let(:article) { create(:article) }
  let(:user) { create(:user) }
  let(:course) { create(:course, start: 1.month.ago, end: 1.month.from_now) }
  let(:article_course) { create(:articles_course, article:, course:) }
  let(:revision1) do
    create(:revision, article:,
           characters: 123,
           features: { 'num_ref' => 4 },
           features_previous: { 'num_ref' => 0 },
           user_id: 25)
  end
  let(:revision2) do
    create(:revision, article:,
           characters: -65,
           features: { 'num_ref' => 1 },
           features_previous: { 'num_ref' => 2 },
           user_id: 1)
  end
  let(:revision3) do
    create(:revision, article:,
           characters: 225,
           features: { 'num_ref' => 3 },
           features_previous: { 'num_ref' => 3 },
           user_id: 25)
  end
  let(:revision4) do
    create(:revision, article:,
            characters: 34,
            deleted: true, # deleted revision
            features: { 'num_ref' => 2 },
            features_previous: { 'num_ref' => 0 },
            user_id: 6)
  end
  let(:revisions) { [revision1, revision2, revision3, revision4] }
  let(:article_course_timeslice) do
    create(:article_course_timeslice,
           article_course_id: article_course.id,
           character_sum: 100,
           references_count: 3,
           user_ids: [2, 4])
  end
  let(:subject) { article_course_timeslice.update_cache_from_revisions revisions }

  describe '.update_cache_from_revisions' do
    it 'updates cache correctly' do
      expect(article_course_timeslice.character_sum).to eq(100)
      expect(article_course_timeslice.references_count).to eq(3)
      expect(article_course_timeslice.user_ids).to eq([2, 4])
      subject
      expect(article_course_timeslice.character_sum).to eq(448)
      expect(article_course_timeslice.references_count).to eq(6)
      expect(article_course_timeslice.user_ids).to eq([2, 4, 25, 1])
    end
  end
end
