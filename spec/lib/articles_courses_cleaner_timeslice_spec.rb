# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/articles_courses_cleaner_timeslice"

describe ArticlesCoursesCleanerTimeslice do
  let(:enwiki) { Wiki.get_or_create(project: 'wikipedia', language: 'en') }
  let(:wikidata) { Wiki.get_or_create(project: 'wikidata', language: nil) }
  let(:course) { create(:course, start: '2024-01-01', end: '2024-04-20') }
  # let(:enwiki_course) { create(:courses_wiki, course:, wiki: enwiki) }
  # let(:wikidata_course) { create(:courses_wiki, course:, wiki: wikidata) }
  let(:article1) { create(:article, wiki: enwiki) }
  let(:article2) { create(:article, wiki: wikidata) }
  let(:article3) { create(:article, wiki: wikidata) }

  describe '.remove_bad_articles_courses' do
    before do
      stub_wiki_validation
      create(:articles_course, course:, article: article1)
      create(:articles_course, course:, article: article2)
      create(:articles_course, course:, article: article3)
    end

    it 'removes ArticlesCourses that belong to a deleted wiki' do
      expect(course.articles_courses.size).to eq(3)
      # Wikidata courses_wikis record was deleted
      described_class.remove_bad_articles_courses(course, wikidata.id)
      expect(course.articles_courses.size).to eq(1)
    end
  end
end
