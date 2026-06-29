# frozen_string_literal: true

require 'rails_helper'

describe DeleteCourseWorker do
  let(:enwiki) { Wiki.get_or_create(project: 'wikipedia', language: 'en') }
  let(:course) { create(:course, slug: 'School/Course_(Term)') }
  let(:other_course) { create(:course, slug: 'Other/Course_(Term)') }
  let(:user) { create(:user) }
  let(:article) { create(:article, wiki_id: enwiki.id) }

  before do
    stub_wiki_validation
    # Avoid making real on-wiki edits when the course is deleted.
    allow(WikiCourseEdits).to receive(:new)
  end

  def create_timeslices_for(some_course)
    create(:article_course_timeslice, course: some_course, article_id: article.id)
    create(:course_user_wiki_timeslice, course: some_course, user_id: user.id, wiki: enwiki)
    create(:course_wiki_timeslice, course: some_course, wiki: enwiki)
    create(:article_course_user_wiki_timeslice, course: some_course, wiki: enwiki,
                                                article_id: article.id, user_id: user.id)
  end

  it 'destroys the course' do
    create_timeslices_for(course)

    described_class.new.perform(course.id, user.id)

    expect(Course.exists?(course.id)).to be false
  end

  it 'deletes the course timeslices across all four timeslice tables' do
    create_timeslices_for(course)

    described_class.new.perform(course.id, user.id)

    expect(ArticleCourseTimeslice.where(course_id: course.id)).to be_empty
    expect(CourseUserWikiTimeslice.where(course_id: course.id)).to be_empty
    expect(CourseWikiTimeslice.where(course_id: course.id)).to be_empty
    expect(ArticleCourseUserWikiTimeslice.where(course_id: course.id)).to be_empty
  end

  it 'leaves timeslices belonging to other courses intact' do
    create_timeslices_for(course)
    create_timeslices_for(other_course)

    described_class.new.perform(course.id, user.id)

    expect(ArticleCourseTimeslice.where(course_id: other_course.id).count).to eq(1)
    expect(CourseUserWikiTimeslice.where(course_id: other_course.id).count).to eq(1)
    expect(CourseWikiTimeslice.where(course_id: other_course.id).count).to eq(1)
    expect(ArticleCourseUserWikiTimeslice.where(course_id: other_course.id).count).to eq(1)
  end
end
