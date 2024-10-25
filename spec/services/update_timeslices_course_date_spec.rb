# frozen_string_literal: true

require 'rails_helper'

describe UpdateTimeslicesCourseDate do
  let(:course) { create(:course, start: '2021-01-24', end: '2021-01-30') }
  let(:enwiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
  let(:updater) { described_class.new(course).run }
  let(:user1) { create(:user, username: 'Ragesoss') }
  let(:user2) { create(:user, username: 'Oleryhlolsson') }
  let(:manager) { TimesliceManager.new(course) }
  let(:article1) { create(:article, wiki: enwiki) }
  let(:article2) { create(:article, wiki: enwiki) }

  before do
    stub_wiki_validation
    # Add two users
    course.campaigns << Campaign.first
    JoinCourse.new(course:, user: user1, role: 0)
    JoinCourse.new(course:, user: user2, role: 0)
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
    ArticleCourseTimeslice.where(course:, article: article2).last.update(user_ids: [user1.id])
  end

  context 'when the start date changed to a previous date' do
    before do
      course.update(start: '2021-01-20')
    end

    it 'adds new timeslices that needs_update' do
      # There are two users, two articles and one wiki
      expect(course.course_wiki_timeslices.count).to eq(7)
      expect(course.course_wiki_timeslices.needs_update.count).to eq(0)
      expect(course.course_user_wiki_timeslices.count).to eq(14)
      expect(course.article_course_timeslices.count).to eq(14)

      described_class.new(course).run
      # Timeslices from 2021-01-20 to 2021-01-24 were added
      expect(course.course_wiki_timeslices.count).to eq(11)
      expect(course.course_wiki_timeslices.needs_update.count).to eq(4)
      expect(course.course_user_wiki_timeslices.count).to eq(22)
      expect(course.article_course_timeslices.count).to eq(22)
    end
  end

  context 'when the start date changed to a later date' do
    before do
      course.update(start: '2021-01-26')
    end

    it 'deletes timeslices and article courses' do
      # There are two users, two articles and one wiki
      expect(course.course_wiki_timeslices.count).to eq(7)
      # When updating the start date, the timeslice is marked as needs_update
      expect(course.course_wiki_timeslices.needs_update.count).to eq(1)
      expect(course.course_user_wiki_timeslices.count).to eq(14)
      expect(course.article_course_timeslices.count).to eq(14)
      expect(course.articles_courses.count).to eq(2)

      described_class.new(course).run
      # Timeslices from 2021-01-24 to 2021-01-26 were deleted
      expect(course.course_wiki_timeslices.count).to eq(5)
      expect(course.course_wiki_timeslices.needs_update.count).to eq(1)
      expect(course.course_user_wiki_timeslices.count).to eq(10)
      # Article course for article 1 was deleted
      expect(course.articles_courses.count).to eq(1)
      expect(course.article_course_timeslices.count).to eq(5)
    end
  end

  context 'when the end date changed to a later date' do
    before do
      course.update(end: '2021-02-11')
    end

    it 'adds new timeslices that needs_update' do
      # There are two users, two articles and one wiki
      expect(course.course_wiki_timeslices.count).to eq(7)
      expect(course.course_wiki_timeslices.needs_update.count).to eq(0)
      expect(course.course_user_wiki_timeslices.count).to eq(14)
      expect(course.article_course_timeslices.count).to eq(14)

      described_class.new(course).run
      # Timeslices from 2021-01-30 to 2021-02-11 were added
      expect(course.course_wiki_timeslices.count).to eq(19)
      expect(course.course_wiki_timeslices.needs_update.count).to eq(13)
      expect(course.course_user_wiki_timeslices.count).to eq(38)
      expect(course.article_course_timeslices.count).to eq(38)
    end
  end

  context 'when the end date changed to a previous date' do
    before do
      course.update(end: '2021-01-29')
    end

    it 'deletes timeslices and article courses' do
      # There are two users, two articles and one wiki
      expect(course.course_wiki_timeslices.count).to eq(7)
      # When updating the start date, the timeslice is marked as needs_update
      expect(course.course_wiki_timeslices.needs_update.count).to eq(1)
      expect(course.course_user_wiki_timeslices.count).to eq(14)
      expect(course.article_course_timeslices.count).to eq(14)
      expect(course.articles_courses.count).to eq(2)

      described_class.new(course).run
      # Timeslices for 2021-01-30 were deleted
      expect(course.course_wiki_timeslices.count).to eq(6)
      expect(course.course_wiki_timeslices.needs_update.count).to eq(1)
      expect(course.course_user_wiki_timeslices.count).to eq(12)
      # Article course for article 2 was deleted
      expect(course.articles_courses.count).to eq(1)
      expect(course.article_course_timeslices.count).to eq(6)
    end
  end
end
