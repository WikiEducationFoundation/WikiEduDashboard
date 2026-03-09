# frozen_string_literal: true

require 'rails_helper'

describe 'AI edit alerts stats', type: :feature, js: true do
  let(:admin) { create(:admin) }
  let(:campaign) { create(:campaign) }
  let(:course) { create(:course) }
  let(:user1) { create(:user) }
  let(:user2) { create(:user, username: 'some username') }
  let(:article1) { create(:article, title: 'Hockey') }
  let(:article2) { create(:article, title: 'Selfie') }

  let!(:alert) do
    create(:alert, type: 'AiEditAlert', course_id: course.id, user_id: user1.id, article: article1)
  end
  let!(:nh_alert) do
    create(:alert, type: 'HighQualityArticleEditAlert', course_id: course.id,
    user_id: user2.id, article: article2)
  end

  before do
    login_as admin
    course.campaigns << campaign
  end

  describe 'INDEX page' do
    it 'has sections' do
      visit "/ai_edit_alerts_stats/#{campaign.slug}"
      expect(page).to have_content 'Alerts with recent followup'
      expect(page).to have_content 'Recent alerts for students with multiple alerts'
      expect(page).to have_content 'Recent alerts in mainspace'
    end

    it 'has data' do
      visit "/ai_edit_alerts_stats/#{campaign.slug}"
      expect(page).to have_content 'Hockey'
      expect(page).not_to have_content 'Selfie'
      expect(page).to have_content 'Ragesock'
      expect(page).not_to have_content 'some username'
    end
  end
end
