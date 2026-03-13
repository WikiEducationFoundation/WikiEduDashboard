# frozen_string_literal: true

require 'rails_helper'

describe 'Article scoped flag behavior', type: :model do
  describe '#only_scoped_articles_course?' do
    it 'returns false for a course without the article_scoped flag' do
      course = create(:basic_course, start: '2024-01-01', end: '2024-12-31')
      expect(course.only_scoped_articles_course?).to eq(false)
    end

    it 'returns true for a course with the article_scoped flag set' do
      course = create(:basic_course, start: '2024-01-01', end: '2024-12-31',
                                     flags: { article_scoped: true })
      expect(course.only_scoped_articles_course?).to eq(true)
    end

    it 'returns true for an Editathon with the article_scoped flag set' do
      course = create(:editathon, start: '2024-01-01', end: '2024-12-31',
                                  flags: { article_scoped: true })
      expect(course.only_scoped_articles_course?).to eq(true)
    end

    it 'still returns true for ArticleScopedProgram via its own override' do
      course = create(:article_scoped_program, start: '2024-01-01', end: '2024-12-31')
      expect(course.only_scoped_articles_course?).to eq(true)
    end

    it 'still returns true for VisitingScholarship via its own override' do
      course = create(:visiting_scholarship, start: '2024-01-01', end: '2024-12-31')
      expect(course.only_scoped_articles_course?).to eq(true)
    end
  end

  describe '#scoped_article? with flag' do
    before do
      create(:article, title: 'Category_article')
      create(:article, title: 'Unassigned_article', mw_page_id: 400)
      create(:assignment, course: course, article: article, article_title: article.title, wiki: wiki)
      create(:categories_courses, course: course, category: category)
    end

    let(:wiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
    let(:course) do
      create(:basic_course, start: '2024-01-01', end: '2024-12-31',
                            flags: { article_scoped: true })
    end
    let(:category) { create(:category, wiki: wiki, article_titles: ['Category_article']) }
    let(:article) { create(:article, title: 'Assigned_article', mw_page_id: 345) }

    it 'considers articles in categories as scoped articles' do
      expect(course.scoped_article?(wiki, 'Category_article', 90)).to eq(true)
    end

    it 'considers assigned articles as scoped articles even if title changed' do
      expect(course.scoped_article?(wiki, 'assigned article', 345)).to eq(true)
    end

    it 'returns false for unassigned articles' do
      expect(course.scoped_article?(wiki, 'Unassigned_article', 400)).to eq(false)
    end
  end

  describe '#scoped_article? without flag' do
    let(:wiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
    let(:course) { create(:basic_course, start: '2024-01-01', end: '2024-12-31') }

    it 'considers all articles as scoped when flag is not set' do
      expect(course.scoped_article?(wiki, 'Any_article', 999)).to eq(true)
    end
  end

  describe '#scoped_article_timeslices with flag' do
    let(:course) do
      create(:basic_course, start: '2024-01-01', end: '2024-12-31',
                            flags: { article_scoped: true })
    end
    let(:article) { create(:article) }
    let(:other_article) { create(:article) }

    before do
      create(:assignment, course: course, article: article,
                          article_title: article.title)
      create(:article_course_timeslice, course: course, article: article,
                                        start: course.start, end: course.end)
      create(:article_course_timeslice, course: course, article: other_article,
                                        start: course.start, end: course.end)
    end

    it 'only returns timeslices for scoped articles' do
      expect(course.scoped_article_timeslices.pluck(:article_id)).to include(article.id)
      expect(course.scoped_article_timeslices.pluck(:article_id)).not_to include(other_article.id)
    end
  end

  describe '#scoped_article_timeslices without flag' do
    let(:course) { create(:basic_course, start: '2024-01-01', end: '2024-12-31') }
    let(:article) { create(:article) }
    let(:other_article) { create(:article) }

    before do
      create(:article_course_timeslice, course: course, article: article,
                                        start: course.start, end: course.end)
      create(:article_course_timeslice, course: course, article: other_article,
                                        start: course.start, end: course.end)
    end

    it 'returns all timeslices when flag is not set' do
      expect(course.scoped_article_timeslices.pluck(:article_id)).to include(article.id, other_article.id)
    end
  end
end
