# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/analytics/course_edits_csv_builder"

describe CourseEditsCsvBuilder do
  let(:course) { create(:course) }
  let(:user) { create(:user) }
  let(:article) { create(:article) }
  let!(:courses_user) { create(:courses_user, course: course, user: user) }
  let(:revision_count) { 5 }
  let(:subject) { described_class.new(course).generate_csv }
  before do
    # revisions during the course
    revision_count.times do |i|
      create(:revision, mw_rev_id: i, user: user, date: course.start + 1.minute, article: article)
    end
    # revision outside the course
    create(:revision, mw_rev_id: 123, user: user, date: course.start - 1.minute)
  end

  it 'creates a CSV with a header and a row of data for each course revision' do
    expect(subject.split("\n").count).to eq(revision_count + 1)
  end
end
