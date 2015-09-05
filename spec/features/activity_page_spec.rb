require 'rails_helper'

describe 'activity page', type: :feature, js: true do
  before do
    include Devise::TestHelpers, type: :feature
    Capybara.current_driver = :selenium
  end

  before :each do
    create(:cohort,
           id: 1,
           title: 'Fall 2015')

    if page.driver.is_a?(Capybara::Webkit::Driver)
      page.driver.allow_url 'fonts.googleapis.com'
      page.driver.allow_url 'maxcdn.bootstrapcdn.com'
      page.driver.allow_url 'cdn.ravenjs.com'
      # page.driver.block_unknown_urls  # suppress warnings
    end
    login_as(user, scope: :user)
    visit root_path
  end

  describe 'non-admins' do
    let(:user) { create(:user, id: 2) }
    it 'shouldn\'t be viewable by non-admins' do
      within '.container .home' do
        expect(page).not_to have_content 'Activity'
      end
    end
  end

  describe 'admins' do
    let!(:article)  { create(:article, namespace: 118) }
    let!(:user)     { create(:admin) }
    let!(:revision) do
      create(:revision, article_id: article.id, wp10: 50, user_id: user.id)
    end

    before do
      allow(RevisionAnalyticsService).to receive(:dyk_eligible)
        .and_return([article])
    end

    it 'should be viewable by admins' do
      within '.container .home' do
        expect(page).to have_content 'Activity'
      end
    end

    it 'displays a list of DYK-eligible articles' do
      click_link 'Recent Activity'
      sleep 1
      expect(page).to have_content article.title.gsub('_', ' ')
    end
  end
end
