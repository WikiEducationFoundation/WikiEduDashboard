# frozen_string_literal: true

require 'rails_helper'

describe MarkPurgeableCoursesWorker do
  let(:enwiki) { Wiki.get_or_create(project: 'wikipedia', language: 'en') }
  let(:old_course) do
    create(:course, slug: 'School/Old_(Term)', start: 2.years.ago, end: 1.year.ago)
  end

  it 'flags eligible courses as purgeable' do
    create(:course_wiki_timeslice, course: old_course, wiki: enwiki)

    described_class.new.perform

    expect(old_course.reload.purgeable?).to be true
  end
end
