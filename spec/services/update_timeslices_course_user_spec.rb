# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/timeslice_manager"

describe UpdateTimeslicesCourseUser do
  before { stub_const('TimesliceManager::TIMESLICE_DURATION', 86400) }

  let(:start) { '2021-01-24'.to_datetime }
  let(:course) { create(:course, start:, end: '2021-01-30') }
  let(:enwiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
  let(:updater) { described_class.new(course).run }
  let(:user1) { create(:user, username: 'Ragesoss') }
  let(:user2) { create(:user, username: 'Oleryhlolsson') }
  let(:user3) { create(:user, username: 'erika') }
  let(:manager) { TimesliceManager.new(course) }
  let(:wikidata_article) { create(:article, wiki: wikidata) }
  let(:article1) { create(:article, wiki: enwiki) }
  let(:article2) { create(:article, wiki: enwiki) }
  let(:update_logs) do
    { 'update_logs' => { 1 => { 'start_time' => 3.minutes.ago,
      'end_time' => 2.minutes.ago } } }
  end

  context 'when some course user was removed' do
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

      create(:course_user_wiki_timeslice, course:, user: user1, wiki: enwiki)
      create(:course_user_wiki_timeslice, course:, user: user2, wiki: enwiki)

      create(:article_course_timeslice, course:, article: article1, start:, user_ids: [user1.id])
      create(:article_course_timeslice, course:, article: article2, start:,
      user_ids: [user1.id, user2.id])
      create(:article_course_timeslice, course:, article: article2, start: start + 1.day,
      user_ids: [user2.id])
      create(:article_course_timeslice, course:, article: article2, start: start + 2.days,
      user_ids: [user1.id])
      # Delete course user
      CoursesUsers.find_by(course:, user: user1).delete
    end

    it 'returns immediately if no previous update' do
      # TODO: improve this spec because it doesn't make a lot of sense
      # There are two users, two articles and one wiki
      expect(course.course_wiki_timeslices.count).to eq(7)
      expect(course.course_user_wiki_timeslices.count).to eq(2)
      expect(course.article_course_timeslices.count).to eq(4)
      expect(course.articles.count).to eq(2)
      expect(course.articles_courses.count).to eq(2)

      described_class.new(course).run

      # Nothing changed
      expect(course.course_wiki_timeslices.count).to eq(7)
      expect(course.course_user_wiki_timeslices.count).to eq(2)
      expect(course.article_course_timeslices.count).to eq(4)
      expect(course.articles.count).to eq(2)
      expect(course.articles_courses.count).to eq(2)
    end

    it 'removes course user wiki timeslices and updates course wiki timeslices' do
      # Set previous update
      course.flags = update_logs
      course.save

      # There are two users, two articles and one wiki
      expect(course.course_wiki_timeslices.count).to eq(7)
      expect(course.course_user_wiki_timeslices.count).to eq(2)
      expect(course.article_course_timeslices.count).to eq(4)
      expect(course.articles.count).to eq(2)
      expect(course.articles_courses.count).to eq(2)

      described_class.new(course).run
      # There is one user, one article and one wiki
      expect(course.course_wiki_timeslices.count).to eq(7)
      expect(course.course_wiki_timeslices.needs_update.count).to eq(2)
      expect(course.course_user_wiki_timeslices.count).to eq(1)
      expect(course.articles.count).to eq(1)
      expect(course.articles_courses.count).to eq(1)
    end
  end

  context 'when some course user was added' do
    before do
      stub_wiki_validation
      # Add one user and create timeslices
      course.campaigns << Campaign.first
      course_user = CoursesUsers.create(user: user1, course:,
                                        role: CoursesUsers::Roles::STUDENT_ROLE)
      course_user.update(created_at: 2.hours.ago)

      manager.create_timeslices_for_new_course_wiki_records([enwiki])
      create(:course_user_wiki_timeslice, course:, user: user1, wiki: enwiki)

      # add the new user
      JoinCourse.new(course:, user: user2, role: CoursesUsers::Roles::STUDENT_ROLE)
      JoinCourse.new(course:, user: user3, role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    end

    it 'returns immediately if no previous update' do
      # There is one user and one wiki
      expect(course.course_wiki_timeslices.count).to eq(7)
      expect(course.course_user_wiki_timeslices.count).to eq(1)

      VCR.use_cassette 'course_user_updater' do
        described_class.new(course).run
      end

      # There is one user and one wiki
      expect(course.course_wiki_timeslices.count).to eq(7)
      # No timeslice was marked as needs_update
      expect(course.course_wiki_timeslices.needs_update.count).to eq(0)
      expect(course.course_user_wiki_timeslices.count).to eq(1)
    end

    it 'updates course wiki timeslices if previous update' do
      course.flags = update_logs
      course.save
      # There is one user and one wiki
      expect(course.course_wiki_timeslices.count).to eq(7)
      expect(course.course_user_wiki_timeslices.count).to eq(1)

      VCR.use_cassette 'course_user_updater' do
        described_class.new(course).run
      end

      # There are two student users and one wiki
      expect(course.course_wiki_timeslices.count).to eq(7)
      expect(course.course_wiki_timeslices.needs_update.count).to eq(6)
      expect(course.course_user_wiki_timeslices.count).to eq(1)
    end

    it 'doesnt update course wiki timeslices twice' do
      course.flags = update_logs
      course.save

      expect(course.course_wiki_timeslices.count).to eq(7)
      expect(course.course_wiki_timeslices.needs_update.count).to eq(0)

      VCR.use_cassette 'course_user_updater' do
        described_class.new(course).run
      end

      expect(course.course_wiki_timeslices.count).to eq(7)
      expect(course.course_wiki_timeslices.needs_update.count).to eq(6)

      # Reset needs_update to false
      course.course_wiki_timeslices.update(needs_update: false)

      VCR.use_cassette 'course_user_updater' do
        described_class.new(course).run
      end

      # Timeslices weren't set to reprocess again
      expect(course.course_wiki_timeslices.count).to eq(7)
      expect(course.course_wiki_timeslices.needs_update.count).to eq(0)
    end
  end
end
