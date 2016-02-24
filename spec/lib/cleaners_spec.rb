require 'rails_helper'
require "#{Rails.root}/lib/cleaners"

describe Cleaners do
  describe '.remove_bad_articles_courses' do
    it 'should remove ArticlesCourses that do not belong' do
      create(:course,
             id: 1,
             start: Time.zone.today - 1.month,
             end: Time.zone.today + 1.month,
             title: 'Underwater basket-weaving')
      create(:user,
             id: 1)
      create(:user,
             id: 2)
      # A user who is not a student, so they should not have ArticlesCourses
      create(:courses_user,
             course_id: 1,
             user_id: 1,
             role: 2)
      create(:courses_user,
             course_id: 1,
             user_id: 2,
             role: 0)
      create(:article,
             id: 1)
      create(:revision,
             user_id: 1,
             article_id: 1,
             date: Time.zone.today)
      # An ArticlesCourse that should be removed
      create(:articles_course,
             course_id: 1,
             article_id: 1)

      Cleaners.remove_bad_articles_courses
      expect(ArticlesCourses.all.count).to eq(0)
      # Now recreate it where another classmate touched it
      create(:revision,
             user_id: 2,
             article_id: 1,
             date: Time.zone.today)
      create(:articles_course,
             course_id: 1,
             article_id: 1)
      Cleaners.remove_bad_articles_courses
      expect(ArticlesCourses.all.count).to eq(1)
    end
  end

  describe '.rebuild_articles_courses' do
    it 'should create ArticlesCourses for current students' do
      create(:course,
             id: 1,
             start: 1.month.ago,
             end: Time.zone.today + 1.year)
      create(:course,
             id: 2,
             start: 1.month.ago,
             end: Time.zone.today + 1.year)
      create(:revision,
             id: 661324615,
             article_id: 46640378,
             user_id: 24593901,
             date: 1.day.ago)
      create(:article,
             id: 46640378,
             namespace: 0)
      create(:user,
             id: 24593901,
             wiki_id: 'Rothscak')
      create(:courses_user,
             course_id: 1,
             user_id: 24593901)
      Cleaners.rebuild_articles_courses
      articles_for_course = ArticlesCourses.where(course_id: 1)
      expect(articles_for_course.count).to eq(1)
    end
  end

  describe '.repair_case_variant_assignment_titles' do
    it 'updates titles for assignments to match the corresponding article' do
      create(:assignment, id: 1, article_id: 1,
                          article_title: 'Bombus_hortorum', user_id: 1, role: 0)
      create(:assignment, id: 2, article_id: 1,
                          article_title: 'bombus hortorum', user_id: 2, role: 0)
      create(:article, id: 1, title: 'Bombus_hortorum')
      Cleaners.repair_case_variant_assignment_titles

      expect(Assignment.find(1).article_title).to eq('Bombus_hortorum')
      expect(Assignment.find(2).article_title).to eq('Bombus_hortorum')
    end
    it 'capitalizes the first letter of titles if there is no article_id' do
      create(:assignment, id: 1, article_id: nil, article_title: 'bombus_hortorum')
      create(:assignment, id: 2, article_id: nil, article_title: 'Bombus_hortorum')
      create(:assignment, id: 3, article_id: nil, article_title: 'Áombus_hortorum')
      create(:assignment, id: 4, article_id: nil, article_title: 'áombus_hortorum')

      Cleaners.repair_case_variant_assignment_titles
      expect(Assignment.find(1).article_title).to eq('Bombus_hortorum')
      expect(Assignment.find(2).article_title).to eq('Bombus_hortorum')
      expect(Assignment.find(3).article_title).to eq('Áombus_hortorum')
      expect(Assignment.find(4).article_title).to eq('Áombus_hortorum')
    end
  end

  describe '.match_assignment_titles_with_case_variant_articles_that_exist' do
    it 'updates assignment article titles when it should' do
      VCR.use_cassette 'cleaners/assignment_title_cleanup' do
        create(:assignment, id: 1, article_id: nil, article_title: 'Robert_montgomery_(artist)')
        create(:assignment, id: 2,
                            article_id: nil,
                            article_title: 'American_institute_of_wine_&_food')

        Cleaners.match_assignment_titles_with_case_variant_articles_that_exist(2)
        expect(Assignment.find(1).article_title).to eq('Robert_Montgomery_(artist)')
        expect(Assignment.find(2).article_title).to eq('American_Institute_of_Wine_&_Food')
      end
    end

    # This cleaner is intended to clean up articles that got their case mangled
    # by the .capitalize method, which downcased everything but the first letter.
    # We don't want to query the Wikipedia API for assignment that were not affected
    # by this bug, or that have already been repaired.
    it 'should not try to update titles that are mostly downcased' do
      create(:assignment, id: 1, article_id: nil, article_title: 'Robert_Montgomery_(artist)')
      # No VCR cassete is in place, so this will fail if it attempts to query Wikipedia.
      Cleaners.match_assignment_titles_with_case_variant_articles_that_exist(1)
      expect(Assignment.find(1).article_title).to eq('Robert_Montgomery_(artist)')
    end
  end
end
