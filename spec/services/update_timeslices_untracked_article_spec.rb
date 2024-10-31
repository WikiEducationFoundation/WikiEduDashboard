# frozen_string_literal: true

require 'rails_helper'

describe UpdateTimeslicesUntrackedArticle do
  let(:course) { create(:course, start: '2021-01-24', end: '2021-01-30') }
  let(:enwiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
  let(:updater) { described_class.new(course).run }
  let(:user1) { create(:user, username: 'Ragesoss') }
  let(:user2) { create(:user, username: 'Oleryhlolsson') }
  let(:user3) { create(:user, username: 'erika') }
  let(:manager) { TimesliceManager.new(course) }
  let(:wikidata_article) { create(:article, wiki: wikidata) }
  let(:article1) { create(:article, wiki: enwiki) }
  let(:article2) { create(:article, wiki: enwiki) }

  before do
    stub_wiki_validation
    # Add two users
    course.campaigns << Campaign.first
    JoinCourse.new(course:, user: user1, role: CoursesUsers::Roles::STUDENT_ROLE)
    JoinCourse.new(course:, user: user2, role: CoursesUsers::Roles::STUDENT_ROLE)
    manager.create_timeslices_for_new_course_wiki_records([enwiki])
    # Add articles courses and timeslices manually
    create(:articles_course, course:, article: article1, user_ids: [user1.id])
    create(:articles_course, course:, article: article2, user_ids: [user1.id, user2.id])
    manager.create_timeslices_for_new_article_course_records(
      [{ article_id: article1.id, course_id: course.id },
       { article_id: article2.id, course_id: course.id }]
    )
    # Update articles courses timeslices
    ArticleCourseTimeslice.where(course:, article: article1).first.update(user_ids: [user1.id])
    timeslices = ArticleCourseTimeslice.where(course:, article: article2)
    timeslices.first.update(user_ids: [user1.id, user2.id])
    timeslices.second.update(user_ids: [user2.id])
    timeslices.third.update(user_ids: [user1.id])
  end

  context 'when some article was untracked' do
    before do
      # Untrack article
      ArticlesCourses.find_by(article_id: article2.id).update(tracked: false)
    end

    it 'sets course wiki timeslices as needs_update' do
      expect(course.course_wiki_timeslices.where(needs_update: true).count).to eq(0)
      expect(course.article_course_timeslices.where(tracked: false).count).to eq(0)

      described_class.new(course).run

      expect(course.course_wiki_timeslices.where(needs_update: true).count).to eq(3)
      expect(course.article_course_timeslices.where(tracked: false).count).to eq(7)
    end
  end

  context 'when some article was re-tracked' do
    before do
      # Mark timeslices for article 2 as untracked to simulate article2 is untracked
      ArticleCourseTimeslice.where(course:, article: article2).update(tracked: false)
    end

    it 'sets course wiki timeslices as needs_update' do
      expect(course.course_wiki_timeslices.where(needs_update: true).count).to eq(0)
      expect(course.article_course_timeslices.where(tracked: false).count).to eq(7)

      described_class.new(course).run

      expect(course.course_wiki_timeslices.where(needs_update: true).count).to eq(3)
      expect(course.article_course_timeslices.where(tracked: false).count).to eq(0)
    end
  end
end
