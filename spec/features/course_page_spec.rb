require 'rails_helper'

cohort = Figaro.env.cohorts.split(',').last
user_count = 10
article_count = 19
revision_count = 214
slug = 'This_university/This_course_(term_2015)'

describe 'the home page', type: :feature do
  before do
    create(:course,
           id: 1,
           title: 'This course',
           slug: slug,
           start: '2015-01-01'.to_date,
           end: '2015-12-31'.to_date,
           school: 'This university',
           term: 'term 2015',
           listed: 1,
           cohort: cohort
    )

    (1..user_count).each do |i|
      create(:user,
             id: i.to_s,
             wiki_id: "Student #{i}",
             trained: i % 2
      )
      create(:courses_user,
             id: i.to_s,
             course_id: 1,
             user_id: i.to_s
      )
    end

    (1..article_count).each do |i|
      create(:article,
             id: i.to_s,
             title: "Article #{i}",
             namespace: 0
     )
    end
    (1..revision_count).each do |i|
      # Make half of thee articles new ones.
      newness = (i <= article_count) ? i % 2 : 0

      create(:revision,
             id: i.to_s,
             user_id: ((i % user_count) + 1).to_s,
             article_id: ((i % article_count) + 1).to_s,
             date: '2015-03-01'.to_date,
             characters: 9000 + i,
             new_article: newness
      )
    end
    ArticlesCourses.update_from_revisions
    Course.update_all_caches
  end

  before :each do
    if page.driver.is_a?(Capybara::Webkit::Driver)
      page.driver.allow_url 'fonts.googleapis.com'
      page.driver.allow_url 'maxcdn.bootstrapcdn.com'
      # page.driver.block_unknown_urls  # suppress warnings
    end
    visit "/courses/#{slug}"
  end

  describe 'header' do
    it 'should display the course title' do
      title_text = 'This course'
      expect(page.find('.title')).to have_content title_text
    end

    it 'should display school and term' do
      school = 'This university'
      expect(page.find('.title')).to have_content school
      term = 'term 2015'
      expect(page.find('.title')).to have_content term
    end

    it 'should display course-wide statistics' do
      new_articles = (article_count / 2.to_f).ceil.to_s
      expect(page.find('#articles-created')).to have_content new_articles
      expect(page.find('#total-edits')).to have_content revision_count
      expect(page.find('#articles-edited')).to have_content article_count
    end
  end

  
  
end
