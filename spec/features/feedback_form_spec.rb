# frozen_string_literal: true

require 'rails_helper'

describe 'feedback form' do
  let(:slide_with_feedback_link) do
    '/training/instructors/new-instructor-orientation/new-instructor-orientation-complete'
  end

  let(:feedback_link_text) { 'Submit Feedback' }

  context 'from a training module', type: :feature, js: true do
    let(:body) { 'It was great' }
    let(:user) { create(:user) }
    it 'submits successfully for a logged in user' do
      login_as user
      visit slide_with_feedback_link
      click_link feedback_link_text
      within_window(page.windows.last) do
        fill_in 'feedback_form_response_body', with: body
        click_button 'Submit'
        expect(page).to have_content 'Thank you.'
      end
      form = FeedbackFormResponse.last
      expect(form.body).to eq(body)
      expect(form.user_id).to eq(user.id)
      expect(form.subject).to match(slide_with_feedback_link)
    end

    it 'submits successfully for a logged out user' do
      visit slide_with_feedback_link
      click_link feedback_link_text
      within_window(page.windows.last) do
        fill_in 'feedback_form_response_body', with: body
        click_button 'Submit'
        expect(page).to have_content 'Thank you.'
      end
      form = FeedbackFormResponse.last
      expect(form.body).to eq(body)
      expect(form.user_id).to eq(nil)
      expect(form.subject).to match(slide_with_feedback_link)
    end
  end

  context 'with a query param' do
    let(:body) { 'It was great' }
    let(:user) { create(:user) }
    let(:referer) { 'wikipedia.org' }
    it 'submits successfully' do
      login_as user
      visit "/feedback?referer=#{referer}"
      fill_in 'feedback_form_response_body', with: body
      click_button 'Submit'
      expect(page).to have_content 'Thank you.'
      form = FeedbackFormResponse.last
      expect(form.body).to eq(body)
      expect(form.user_id).to eq(user.id)
      expect(form.subject).to match(referer)
    end
  end

  meths = ['#index', '#show']

  meths.each do |meth|
    context meth do
      let(:user) { create(:user) }
      let!(:resp) do
        FeedbackFormResponse.create(body: 'bananas',
                                    subject: 'wikipedia.org',
                                    user_id: user.id)
      end
      let(:text) { 'Feedback' }

      before do
        login_as user
        if meth == '#index'
          visit feedback_form_responses_path
        else
          visit feedback_form_response_path(resp.id)
        end
      end

      context 'non-admin' do
        context 'current user' do
          it 'denies access' do
            expect(page).to have_content "You don't have access to that page"
          end
        end
        context 'logged out' do
          it 'denies access' do
            visit feedback_form_responses_path
            expect(page).to have_content "You don't have access to that page"
          end
        end
      end
      context 'admin' do
        let(:user) { create(:admin) }
        it 'permits' do
          expect(page).to have_content text
          expect(page).to have_content resp.topic
        end
      end
    end
  end
end
