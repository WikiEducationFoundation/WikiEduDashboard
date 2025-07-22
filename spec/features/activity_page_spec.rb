# frozen_string_literal: true

require 'rails_helper'

describe 'activity page', type: :feature, js: true do
  before do
    login_as(user, scope: :user)
    visit '/'
  end

  describe 'non-admins' do
    let(:user) { create(:user) }

    it 'is not linked for non-admins' do
      within '.top-nav' do
        expect(page).not_to have_content 'Admin'
      end
    end
  end

  describe 'admins' do
    let!(:admin)   { create(:admin) }
    let!(:user)    { create(:user) }
    let(:course)   { create(:course, end: 1.year.from_now) }
    let(:course2)  { create(:course, end: 1.year.from_now, slug: 'foo/2') }
    let!(:cu1)     { create(:courses_user, user_id: user.id, course_id: course.id) }
    let!(:cu3)     { create(:courses_user, user_id: admin.id, course_id: course.id) }

    before do
      login_as(admin, scope: :user)
      visit '/'
    end

    it 'is viewable by admins' do
      within '.top-nav' do
        click_link 'Admin'
      end
      click_link 'Recent Activity'
    end

    context 'recent uploads' do
      let!(:upload) do
        create(:commons_upload,
               file_name: 'File:Blowing a raspberry.ogv',
               user_id: user.id,
               uploaded_at: 2.days.ago)
      end

      it 'displays a list of recent uploads' do
        visit '/recent-activity/recent-uploads'
        expect(page).to have_selector('div.upload')
        Capybara.ignore_hidden_elements = false
        expect(page).to have_content 'Blowing a raspberry.ogv'
        Capybara.ignore_hidden_elements = true
      end
    end
  end

  def assert_page_content(content)
    expect(page).to have_content content
  end
end
