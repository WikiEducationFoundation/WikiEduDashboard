# frozen_string_literal: true

require 'rails_helper'

describe PurgeTimeslicesWorker do
  let(:enwiki) { Wiki.get_or_create(project: 'wikipedia', language: 'en') }
  let(:user) { create(:user) }
  let(:article) { create(:article, wiki_id: enwiki.id) }
  let(:other_course) { create(:course, slug: 'Other/Course_(Term)') }
  let(:purgeable_course) do
    create(:course, slug: 'Purgeable/Course_(Term)', flags: { purgeable: true })
  end

  def create_timeslices_for(some_course)
    create(:article_course_timeslice, course: some_course, article_id: article.id)
    create(:course_user_wiki_timeslice, course: some_course, user_id: user.id, wiki: enwiki)
    create(:course_wiki_timeslice, course: some_course, wiki: enwiki)
    create(:article_course_user_wiki_timeslice, course: some_course, wiki: enwiki,
                                                article_id: article.id, user_id: user.id)
  end

  it 'deletes the purgeable course timeslices across all four timeslice tables' do
    create_timeslices_for(purgeable_course)

    described_class.new.perform

    expect(ArticleCourseTimeslice.where(course_id: purgeable_course.id)).to be_empty
    expect(CourseUserWikiTimeslice.where(course_id: purgeable_course.id)).to be_empty
    expect(CourseWikiTimeslice.where(course_id: purgeable_course.id)).to be_empty
    expect(ArticleCourseUserWikiTimeslice.where(course_id: purgeable_course.id)).to be_empty
  end

  it 'leaves timeslices belonging to non-purgeable courses intact' do
    create_timeslices_for(other_course)

    described_class.new.perform

    expect(ArticleCourseTimeslice.where(course_id: other_course.id).count).to eq(1)
    expect(CourseUserWikiTimeslice.where(course_id: other_course.id).count).to eq(1)
    expect(CourseWikiTimeslice.where(course_id: other_course.id).count).to eq(1)
    expect(ArticleCourseUserWikiTimeslice.where(course_id: other_course.id).count).to eq(1)
  end

  it 'clears the purgeable flag and records the purge' do
    course = purgeable_course # create it before the worker runs (let is lazy)

    described_class.new.perform

    course.reload
    expect(course.purgeable?).to be false
    expect(course.purged?).to be true
  end

  it 'purges at most COURSES_PER_RUN courses per run' do
    stub_const('PurgeTimeslicesWorker::COURSES_PER_RUN', 1)
    first = create(:course, slug: 'First/Course_(Term)', flags: { purgeable: true })
    second = create(:course, slug: 'Second/Course_(Term)', flags: { purgeable: true })

    described_class.new.perform

    purged = [first, second].map { |c| c.reload.purged? }
    # Exactly one of the two purgeable courses is purged; the other keeps its flag.
    expect(purged.count(true)).to eq(1)
    expect(purged.count(false)).to eq(1)
  end
end
