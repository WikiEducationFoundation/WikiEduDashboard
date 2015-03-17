require 'rails_helper'

cohort_course_count = 10

cohort = Figaro.env.cohorts.split(',').last

cohort_two = Figaro.env.cohorts.split(',').first
cohort_two_title = cohort_two.gsub('_', ' ').capitalize

describe 'the home page', type: :feature do
  before do
    (1..cohort_course_count).each do |i|
      create(:course,
             id: i.to_s,
             slug: "course_#{i}",
             cohort: cohort
      )
      create(:course,
             id: (i + cohort_course_count).to_s,
             slug: "course_#{i}",
             cohort: cohort_two
      )
      create(:user, id: i.to_s)
      create(:courses_user,
             id: i.to_s,
             course_id: i.to_s,
             user_id: i.to_s
      )
      create(:article,
             id: i.to_s,
             title: 'Selfie',
             namespace: 0
      )
      create(:revision,
             id: i.to_s,
             user_id: i.to_s,
             article_id: i.to_s,
             date: '2015-03-01'.to_date,
             characters: 9000
      )
    end
    Course.update_all_caches
  end

  before :each do
    if page.driver.is_a?(Capybara::Webkit::Driver)
      page.driver.allow_url 'fonts.googleapis.com'
      page.driver.allow_url 'maxcdn.bootstrapcdn.com'
      # page.driver.block_unknown_urls  # suppress warnings
    end
    visit root_path
  end

  describe 'header' do
    it 'should display number of courses accurately' do
      course_count = Course.cohort(cohort).count
      stat_text = "#{course_count} WikiEdu Courses"
      expect(page.find('.stat-display')).to have_content stat_text
    end

    it 'should display number of students accurately' do
      student_count = User.role('student').count
      stat_text = "#{student_count} Student Editors"
      expect(page.find('.stat-display')).to have_content stat_text
    end

    it 'should display number of characters added accurately' do
      character_count = Course.all.sum(:character_sum)
      stat_text = "#{character_count} Characters Added"
      expect(page.find('.stat-display')).to have_content stat_text
    end

    it 'should display number of views accurately' do
      character_count = Course.all.sum(:view_sum)
      stat_text = "#{character_count} Article Views"
      expect(page.find('.stat-display')).to have_content stat_text
    end
  end

  describe 'control bar' do
    it 'should allow sorting via dropdown', js: true do
      find('select.sorts').find(:xpath, 'option[2]').select_option
      expect(page).to have_selector('.course-list__row__characters.sort.desc')
      find('select.sorts').find(:xpath, 'option[3]').select_option
      expect(page).to have_selector('.course-list__row__views.sort.desc')
      find('select.sorts').find(:xpath, 'option[4]').select_option
      expect(page).to have_selector('.course-list__row__students.sort.desc')
      find('select.sorts').find(:xpath, 'option[1]').select_option
      expect(page).to have_selector('.course-list__row__title.sort.asc')
    end

    # This will fail unless there are at least two cohorts in application.yml.
    it 'should allow loading of different cohorts', js: true do
      find('select.cohorts').find(:xpath, 'option[2]').select_option
      expect(page).to have_content(cohort_two_title)
    end
  end

  describe 'course list' do
    it 'should be sortable by title', js: true do
      expect(page).to have_selector('.course-list__row__title.sort.asc')
      find('.course-list__row__title.sort').trigger('click')
      expect(page).to have_selector('.course-list__row__title.sort.desc')
    end

    it 'should be sortable by character count', js: true do
      find('.course-list__row__characters.sort').trigger('click')
      expect(page).to have_selector('.course-list__row__characters.sort.desc')
      find('.course-list__row__characters.sort').trigger('click')
      expect(page).to have_selector('.course-list__row__characters.sort.asc')
    end

    it 'should be sortable by view count', js: true do
      find('.course-list__row__views.sort').trigger('click')
      expect(page).to have_selector('.course-list__row__views.sort.desc')
      find('.course-list__row__views.sort').trigger('click')
      expect(page).to have_selector('.course-list__row__views.sort.asc')
    end

    it 'should be sortable by student count', js: true do
      find('.course-list__row__students.sort').trigger('click')
      expect(page).to have_selector('.course-list__row__students.sort.desc')
      find('.course-list__row__students.sort').trigger('click')
      expect(page).to have_selector('.course-list__row__students.sort.asc')
    end
  end

  describe 'course rows' do
    it 'should allow navigation to a course page', js: true do
      first_course = Course.cohort(cohort).first
      click_link(first_course.id)
      expect(current_path).to eq(course_path(first_course))
    end
  end

  describe 'cohort pages' do
    # This will fail unless there are at least two cohorts in application.yml.
    it 'should load courses from the right cohort' do
      all('.course-list__row > a').each do |course_row_anchor|
        expect(course_row_anchor[:id].to_i).to be <= cohort_course_count
      end
    end

    # This will fail unless there are at least two cohorts in application.yml.
    it 'should load courses from a different cohort' do
      visit "/courses?cohort=#{cohort_two}"
      all('.course-list__row > a').each do |course_row_anchor|
        expect(course_row_anchor[:id].to_i).to be > cohort_course_count
      end
    end
  end

  describe 'non-default locales' do
    it 'should switch languages' do
      visit '/courses?locale=qqq'
      expect(page.find('header')).to have_content 'Application name'
    end
  end
end
