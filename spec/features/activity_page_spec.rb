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

    it 'should be viewable by admins' do
      within '.container .home' do
        expect(page).to have_content 'Activity'
      end
    end

    context 'dyk eligible' do
      before do
        allow(RevisionAnalyticsService).to receive(:dyk_eligible)
          .and_return([article])
      end

      it 'displays a list of DYK-eligible articles' do
        click_link 'Recent Activity'
        sleep 1
        expect(page).to have_content article.title.gsub('_', ' ')
      end
    end

    context 'suspected plagiarism' do
      context 'no plagiarism revisions' do
        before do
          allow(RevisionAnalyticsService).to receive(:suspected_plagiarism)
            .and_return([])
        end

        it 'displays a list of revisions suspected of plagiarism' do
          view_plagiarism_page
          assert_page_content "There are not currently any recent revisions suspected of plagiarism."
        end
      end

      context 'no plagiarism revisions' do
        before do
          allow(RevisionAnalyticsService).to receive(:suspected_plagiarism)
            .and_return([revision])
        end

        it 'displays a list of revisions suspected of plagiarism' do
          view_plagiarism_page
          assert_page_content article.title.gsub('_', ' ')
        end
      end
    end
  end

  def view_plagiarism_page
    click_link 'Recent Activity'
    sleep 1
    click_link 'Plagiarism Flag'
    sleep 1
  end

  def assert_page_content(content)
    expect(page).to have_content content
  end
end
