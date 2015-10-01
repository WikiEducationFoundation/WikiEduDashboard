require 'rails_helper'

describe 'activity page', type: :feature, js: true do
  before do
    include Devise::TestHelpers, type: :feature
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
    let(:article)  { create(:article, namespace: 118) }
    let(:article2) { create(:article, namespace: 118, title: 'pandas') }
    let!(:admin)   { create(:admin) }
    let!(:user)    { create(:user, id: 100) }
    let!(:user2)   { create(:user, id: 101) }
    let(:course)   { create(:course, end: 1.year.from_now) }
    let(:course2)  { create(:course, end: 1.year.from_now) }
    let!(:cu1)     { create(:courses_user, user_id: user.id, course_id: course.id) }
    let!(:cu2)     { create(:courses_user, user_id: user2.id, course_id: course2.id) }
    let!(:cu3)     { create(:courses_user, user_id: admin.id, course_id: course.id) }
    let!(:revision) do
      create(:revision, article_id: article.id, wp10: 50, user_id: user.id, date: 2.days.ago)
    end
    let!(:revision2) do
      create(:revision, article_id: article2.id, wp10: 50, user_id: user2.id, date: 2.days.ago)
    end

    before do
      login_as(admin, scope: :user)
      visit root_path
    end

    it 'should be viewable by admins' do
      within '.container .home' do
        expect(page).to have_content 'Activity'
      end
    end

    context 'dyk eligible' do
      it 'displays a list of DYK-eligible articles' do
        click_link 'Recent Activity'
        sleep 1
        expect(page).to have_content article.title.gsub('_', ' ')
      end

      it 'filters the courses to my courses' do
        # Admin is admin of course 1, should only see user1's revision
        # when checked
        click_link 'Recent Activity'
        sleep 1
        within '.activity-table.list' do
          expect(page).to have_content article.title.tr('_', ' ')
          expect(page).to have_content article2.title.tr('_', ' ')
        end
        check 'Show My Courses Only'
        within '.activity-table.list' do
          expect(page).to have_content article.title.tr('_', ' ')
          expect(page).not_to have_content article2.title.tr('_', ' ')
        end
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

      context 'plagiarism revisions' do
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

    context 'recent edits' do
      before do
        allow(RevisionAnalyticsService).to receive(:recent_edits)
          .and_return([revision])
      end

      it 'displays a list of recent revisions' do
        visit '/recent-activity/recent-edits'
        assert_page_content article.title.gsub('_', ' ')
      end
    end
  end

  def view_plagiarism_page
    click_link 'Recent Activity'
    click_link 'Possible Plagiarism'
  end

  def assert_page_content(content)
    expect(page).to have_content content
  end
end
