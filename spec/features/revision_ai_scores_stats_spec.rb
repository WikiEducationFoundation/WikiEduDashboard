# frozen_string_literal: true

require 'rails_helper'

describe 'Revision AI scores stats', type: :feature, js: true do
  let(:admin) { create(:admin) }
  let(:wiki) { Wiki.get_or_create(project: 'wikipedia', language: 'en') }
  let(:course) { create(:course) }
  let(:user1) { create(:user) }
  let(:user2) { create(:user, username: 'some username') }
  let(:article1) { create(:article, title: 'Hockey') }
  let(:article2) { create(:article, title: 'Selfie') }

  let!(:score) do
    create(:revision_ai_score, revision_id: 1, wiki_id: wiki.id, course_id: course.id,
    user_id: user1.id, article: article1, avg_ai_likelihood: 0.3, max_ai_likelihood: 0.4,
    revision_datetime: '2025-12-06'.to_datetime)
  end

  before do
    login_as admin
  end

  describe 'INDEX page' do
    it 'has sections' do
      visit '/revision_ai_scores_stats'
      expect(page).to have_content 'Daily checks by namespace'
      expect(page).to have_content 'Avg AI likelihood distribution per day'
      expect(page).to have_content 'Max AI likelihood distribution per day'
      expect(page).to have_content 'Overall avg AI likelihood distribution'
      expect(page).to have_content 'Overall max AI likelihood distribution'
    end
  end
end
