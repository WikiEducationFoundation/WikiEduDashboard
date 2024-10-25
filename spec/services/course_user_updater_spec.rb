# frozen_string_literal: true

require 'rails_helper'

describe CourseUserUpdater do
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
      # Delete course user
      CoursesUsers.find_by(course:, user: user1).delete
    end

    it 'removes course user wiki timeslices and updates course wiki timeslices' do
      # There are two users, two articles and one wiki
      expect(course.course_wiki_timeslices.count).to eq(7)
      expect(course.course_user_wiki_timeslices.count).to eq(14)
      expect(course.article_course_timeslices.count).to eq(14)
      expect(course.articles.count).to eq(2)
      expect(course.articles_courses.count).to eq(2)

      described_class.new(course).run
      # There is one user, one article and one wiki
      expect(course.course_wiki_timeslices.count).to eq(7)
      expect(course.course_wiki_timeslices.needs_update.count).to eq(2)
      expect(course.course_user_wiki_timeslices.count).to eq(7)
      expect(course.articles.count).to eq(1)
      expect(course.articles_courses.count).to eq(1)
    end
  end

  context 'when some course user was added' do
    before do
      stub_wiki_validation
      # Add one user and create timeslices
      course.campaigns << Campaign.first
      JoinCourse.new(course:, user: user1, role: CoursesUsers::Roles::STUDENT_ROLE)
      manager.create_timeslices_for_new_course_wiki_records([enwiki])

      # add the new user
      JoinCourse.new(course:, user: user2, role: CoursesUsers::Roles::STUDENT_ROLE)
      JoinCourse.new(course:, user: user3, role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    end

    it 'only adds course user wiki timeslices if no previous update' do
      # There is one user and one wiki
      expect(course.course_wiki_timeslices.count).to eq(7)
      expect(course.course_user_wiki_timeslices.count).to eq(7)

      VCR.use_cassette 'course_user_updater' do
        described_class.new(course).run
      end

      # There are two users and one wiki
      expect(course.course_wiki_timeslices.count).to eq(7)
      # No timeslice was marked as needs_update
      expect(course.course_wiki_timeslices.needs_update.count).to eq(0)
      expect(course.course_user_wiki_timeslices.count).to eq(14)
    end

    it 'adds course user wiki timeslices and updates course wiki timeslices if previous update' do
      course.flags[:first_update] = true
      course.save
      # There is one user and one wiki
      expect(course.course_wiki_timeslices.count).to eq(7)
      expect(course.course_user_wiki_timeslices.count).to eq(7)

      VCR.use_cassette 'course_user_updater' do
        described_class.new(course).run
      end

      # There are two student users and one wiki
      expect(course.course_wiki_timeslices.count).to eq(7)
      expect(course.course_wiki_timeslices.needs_update.count).to eq(6)
      expect(course.course_user_wiki_timeslices.count).to eq(14)
    end
  end
end
