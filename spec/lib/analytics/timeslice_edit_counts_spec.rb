# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/analytics/timeslice_edit_counts"

describe TimesliceEditCounts do
  let(:en_wiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
  let(:wikidata) { create(:wiki, project: 'wikidata', language: nil) }
  let(:course) { create(:course) }

  def article(title, namespace: Article::Namespaces::MAINSPACE, wiki: en_wiki)
    create(:article, title:, namespace:, wiki:)
  end

  def add_edits(course, article, revision_count, tracked: true)
    create(:article_course_timeslice, course:, article:, revision_count:, tracked:,
                                      start: 1.month.ago, end: 1.month.ago + 1.day)
  end

  describe '.by_namespace' do
    it 'sums the tracked edits of each namespace' do
      add_edits(course, article('Main_one'), 3)
      add_edits(course, article('Main_two'), 4)
      add_edits(course, article('Talk', namespace: Article::Namespaces::TALK), 5)
      add_edits(course, article('User', namespace: Article::Namespaces::USER), 6)

      expect(described_class.by_namespace(course)).to eq(0 => 7, 1 => 5, 2 => 6)
    end

    it 'ignores untracked timeslices and other namespaces' do
      add_edits(course, article('Untracked'), 3, tracked: false)
      add_edits(course, article('Template', namespace: Article::Namespaces::TEMPLATE), 4)

      expect(described_class.by_namespace(course)).to eq({})
    end

    it 'only counts scoped articles for article scoped courses' do
      scoped_course = create(:article_scoped_program)
      scoped = article('Scoped')
      create(:assignment, course: scoped_course, article: scoped, article_title: scoped.title)
      add_edits(scoped_course, scoped, 3)
      add_edits(scoped_course, article('Unscoped'), 4)

      expect(described_class.by_namespace(scoped_course)).to eq(0 => 3)
    end
  end

  describe '.by_course_and_namespace' do
    it 'sums the tracked edits of each course and namespace' do
      other_course = create(:course, slug: 'Other/Course_(term)')
      add_edits(course, article('Main'), 3)
      add_edits(course, article('Talk', namespace: Article::Namespaces::TALK), 5)
      add_edits(other_course, article('Other_main'), 4)

      expect(described_class.by_course_and_namespace([course.id, other_course.id]))
        .to eq([course.id, 0] => 3, [course.id, 1] => 5, [other_course.id, 0] => 4)
    end

    it 'only counts scoped articles for article scoped courses' do
      scoped_course = create(:article_scoped_program)
      scoped = article('Scoped')
      create(:assignment, course: scoped_course, article: scoped, article_title: scoped.title)
      create(:articles_course, course: scoped_course, article: scoped)
      add_edits(scoped_course, scoped, 3)
      add_edits(scoped_course, article('Unscoped'), 4)
      add_edits(course, article('Main'), 5)

      expect(described_class.by_course_and_namespace([scoped_course.id, course.id]))
        .to eq([scoped_course.id, 0] => 3, [course.id, 0] => 5)
    end

    it 'only counts scoped articles for courses with the article_scoped flag' do
      course.update(flags: { article_scoped: true })
      scoped = article('Scoped')
      create(:assignment, course:, article: scoped, article_title: scoped.title)
      create(:articles_course, course:, article: scoped)
      add_edits(course, scoped, 3)
      add_edits(course, article('Unscoped'), 4)

      expect(described_class.by_course_and_namespace([course.id])).to eq([course.id, 0] => 3)
    end
  end

  describe '.by_wiki' do
    before { stub_wiki_validation }

    it 'sums the tracked edits of each wiki' do
      add_edits(course, article('Main'), 3)
      add_edits(course, article('Talk', namespace: Article::Namespaces::TALK), 5)
      add_edits(course, article('Q42', wiki: wikidata), 4)

      expect(described_class.by_wiki(course)).to eq(en_wiki.id => 8, wikidata.id => 4)
    end
  end
end
