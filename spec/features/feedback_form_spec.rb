require 'rails_helper'

NEW_INSTRUCTOR_ORIENTATION_ID = 3

describe 'feedback form' do
  context 'from a training module', type: :feature, js: true do
    let(:body) { 'It was great' }
    let(:user) { create(:user) }
    it 'submits successfullyfor a logged in user' do
      login_as user
      mod = TrainingModule.find(NEW_INSTRUCTOR_ORIENTATION_ID)
      url = "/training/instructors/#{mod.slug}/#{mod.slides.last.slug}"
      visit url
      click_link 'Submit feedback on this module'
      within_window(page.driver.window_handles.last) do
        fill_in 'feedback_form_response_body', with: body
        click_button 'Submit'
        expect(page).to have_content 'Thank you.'
      end
      form = FeedbackFormResponse.last
      expect(form.body).to eq(body)
      expect(form.user_id).to eq(user.id)
      expect(form.subject).to match(url)
    end

    it 'submits successfullyfor a logged out user' do
      mod = TrainingModule.find(NEW_INSTRUCTOR_ORIENTATION_ID)
      url = "/training/instructors/#{mod.slug}/#{mod.slides.last.slug}"
      visit url
      click_link 'Submit feedback on this module'
      within_window(page.driver.window_handles.last) do
        fill_in 'feedback_form_response_body', with: body
        click_button 'Submit'
        expect(page).to have_content 'Thank you.'
      end
      form = FeedbackFormResponse.last
      expect(form.body).to eq(body)
      expect(form.user_id).to eq(nil)
      expect(form.subject).to match(url)
    end
  end

  context 'with a query param' do
    let(:body) { 'It was great' }
    let(:user) { create(:user) }
    let(:referrer) { 'wikipedia.org' }
    it 'submits successfully' do
      login_as user
      visit "/feedback?referrer=#{referrer}"
      fill_in 'feedback_form_response_body', with: body
      click_button 'Submit'
      expect(page).to have_content 'Thank you.'
      form = FeedbackFormResponse.last
      expect(form.body).to eq(body)
      expect(form.user_id).to eq(user.id)
      expect(form.subject).to match(referrer)
    end
  end

  meths = ['#index', '#show']

  meths.each do |meth|
    context meth do
      let(:user) { create(:user) }
      let!(:resp) { FeedbackFormResponse.create(body: 'bananas', subject: 'wikipedia.org') }
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
          expect(page).to have_content resp.subject
        end
      end
    end
  end
end
