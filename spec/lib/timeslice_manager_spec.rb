# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/timeslice_manager"

describe TimesliceManager do
  let(:enwiki) { Wiki.get_or_create(project: 'wikipedia', language: 'en') }
  let(:wikidata) { Wiki.get_or_create(project: 'wikidata', language: nil) }
  let(:wikibooks) { Wiki.get_or_create(language: 'en', project: 'wikibooks') }
  let(:course) { create(:course, start: '2024-01-01', end: '2024-04-20') }
  let(:enwiki_course) { CoursesWikis.find_or_create_by(course:, wiki: enwiki) }
  let(:wikidata_course) { CoursesWikis.find_or_create_by(course:, wiki: wikidata) }
  let(:timeslice_manager) { described_class.new(course) }
  let(:new_article_courses) { [] }
  let(:new_course_users) { [] }
  let(:new_course_wikis) { [] }

  before do
    stub_wiki_validation
    travel_to Date.new(2024, 1, 21)
    enwiki_course
    wikidata_course

    new_course_users << create(:courses_user, id: 1, user_id: 1, course:)
    new_course_users << create(:courses_user, id: 2, user_id: 2, course:)
    new_course_users << create(:courses_user, id: 3, user_id: 3, course:)

    new_article_courses << create(:articles_course, article_id: 1, course:)
    new_article_courses << create(:articles_course, article_id: 2, course:)
    new_article_courses << create(:articles_course, article_id: 3, course:)
  end

  describe '#create_timeslices_for_new_article_course_records' do
    context 'when there are new articles courses' do
      it 'creates article course timeslices for the entire course' do
        expect(course.article_course_timeslices.size).to eq(0)
        timeslice_manager.create_timeslices_for_new_article_course_records(
          new_article_courses
        )
        course.reload
        expect(course.article_course_timeslices.size).to eq(333)
        expect(course.article_course_timeslices.min_by(&:start).start.to_date)
          .to eq(Date.new(2024, 1, 1))
        expect(course.article_course_timeslices.max_by(&:start).start.to_date)
          .to eq(Date.new(2024, 4, 20))
      end
    end
  end

  describe '#create_timeslices_for_new_course_user_records' do
    context 'when there are new courses users' do
      it 'creates course user wiki timeslices for every wiki for the entire course' do
        expect(course.course_user_wiki_timeslices.size).to eq(0)
        timeslice_manager.create_timeslices_for_new_course_user_records(
          new_course_users
        )
        course.reload
        expect(course.course_user_wiki_timeslices.size).to eq(666)
        expect(course.course_user_wiki_timeslices.min_by(&:start).start.to_date)
          .to eq(Date.new(2024, 1, 1))
        expect(course.course_user_wiki_timeslices.max_by(&:start).start.to_date)
          .to eq(Date.new(2024, 4, 20))
      end
    end
  end

  describe '#create_course_wiki_timeslices_for_new_records' do
    before do
      new_course_wikis << create(:courses_wikis, wiki: wikibooks, course:)
    end

    context 'when there are new courses wikis' do
      it 'creates course wiki and course user wiki timeslices for the entire course' do
        expect(course.course_wiki_timeslices.size).to eq(0)
        timeslice_manager.create_timeslices_for_new_course_wiki_records(new_course_wikis)
        course.reload
        # Create course wiki timeslices for the entire course
        expect(course.course_wiki_timeslices.size).to eq(111)
        # Create all the course user wiki timeslices for the existing course users for the new wiki
        expect(course.course_user_wiki_timeslices.first.wiki_id).to eq(wikibooks.id)
        expect(course.course_user_wiki_timeslices.size).to eq(333)
      end
    end
  end
end
