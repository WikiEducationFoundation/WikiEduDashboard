# frozen_string_literal: true

require 'rails_helper'

describe 'feedback pages', type: :feature, js: true do
  describe '/feedback (anonymous)' do
    it 'loads cleanly' do
      visit '/feedback'
      expect(page).to have_content 'feedback'
      expect(page).to be_axe_clean
    end
  end

  describe '/feedback/confirmation' do
    it 'loads cleanly' do
      visit '/feedback/confirmation'
      expect(page).to have_content 'Thank you.'
      expect(page).to be_axe_clean
    end
  end

  describe '/feedback_form_responses (admin)' do
    let(:admin) { create(:admin) }
    let!(:response) do
      FeedbackFormResponse.create(body: 'feedback body',
                                  subject: 'wikipedia.org',
                                  user_id: admin.id)
    end

    before { login_as(admin) }
    after { logout }

    it 'index loads cleanly' do
      visit '/feedback_form_responses'
      expect(page).to have_content 'Feedback Form Responses'
      expect(page).to be_axe_clean
    end

    it 'show loads cleanly' do
      visit "/feedback_form_responses/#{response.id}"
      expect(page).to have_content 'Subject'
      expect(page).to be_axe_clean
    end
  end
end
