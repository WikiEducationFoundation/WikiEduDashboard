require 'rails_helper'

# Wait one second after loading a path
# Allows React to properly load the page
# Remove this after implementing server-side rendering
def js_visit(path)
  visit path
  sleep 1
end

describe 'Students Page', type: :feature, js: true do
  before do
    include Devise::TestHelpers, type: :feature

    allow_any_instance_of(WikiEdits).to receive(:oauth_credentials_valid?).and_return(true)

    @course = create(:course,
                    id: 10001,
                    title: 'This.course',
                    slug: 'This_university.foo/This.course_(term_2015)',
                    start: 3.months.ago,
                    end: 3.months.from_now,
                    school: 'This university.foo',
                    term: 'term 2015',
                    listed: 1,
                    description: 'This is a great course')
    cohort = create(:cohort)
    @course.cohorts << cohort

    @user = create(:user,
                   # avoid mysql duplicate key
                   # why is there an `id` in the user factory
                   # anyway?
                   id: rand(534384389),
                   wiki_id: 'Mr_Tester',
                   real_name: 'Mr. Tester',
                   trained: true)

    create(:courses_user,
           id: 1,
           course_id: @course.id,
           user_id: @user.id)

    article = create(:article,
                     id: 1,
                     title: 'Article_Title',
                     namespace: 0,
                     language: 'es',
                     rating: 'fa')

    create(:articles_course,
           article_id: article.id,
           course_id: @course.id)

    create(:revision,
           id: 1,
           user_id: @user.id,
           article_id: article.id,
           date: Time.zone.today,
           characters: 2,
           views: 10,
           new_article: false)

  end

  it 'should display a list of students' do
    js_visit "/courses/#{@course.slug}/students"
    sleep 1 # Try to avoid issue where this test fails with 0 rows found.
    expect(page).to have_content @user.wiki_id
  end

  it 'should open a list of individual student revisions' do
    js_visit "/courses/#{@course.slug}/students"
    sleep 1 # Try to avoid issue where this test fails with 0 rows found.
    expect(page).not_to have_content 'Article Title'
    page.first('tr.students').click
    sleep 1
    within 'table.users' do
      expect(page).to have_content 'User Contributions'
      expect(page).to have_content 'Article Title'
    end
  end

  describe 'display of user name' do
    let(:user) { create(:user) }
    context 'logged out' do
      it 'does not display real name' do
        js_visit "/courses/#{@course.slug}/students"
        sleep 1 # Try to avoid issue where this test fails with 0 rows found.
        within 'table.users' do
          expect(page).not_to have_content @user.real_name
        end
      end
    end
    context 'logged in' do
      before do
        login_as user
        js_visit "/courses/#{@course.slug}/students"
        sleep 1 # Try to avoid issue where this test fails with 0 rows found.
      end
      after do
        logout user
      end
      context 'non-admin' do
        it 'does not display real name' do
          within 'table.users' do
            expect(page).not_to have_content @user.real_name
          end
        end
      end
      context 'admin' do
        let(:user) { create(:admin) }
        it 'displays real name' do
          within 'table.users' do
            expect(page).to have_content @user.real_name
          end
        end
      end
      context 'instructor' do
        let(:user) { create(:user, permissions: 1) }
        let!(:courses_user) { create(:courses_user, course_id: @course.id, user_id: user.id, role: 1) }
        it 'displays real name' do
          within 'table.users' do
            expect(page).to have_content @user.real_name
          end
        end
      end
    end
  end
end
