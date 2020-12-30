# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/analytics/course_students_csv_builder"

describe CourseStudentsCsvBuilder do
  let(:course) { create(:course) }
  let(:user1) { create(:user, registered_at: course.start + 1.minute, username: 'first_user') }
  let(:user2) { create(:user, registered_at: course.start + 2.minute, username: 'second_user') }
  let(:user3) { create(:user, registered_at: course.start + 3.minute, username: 'third_user') }
  let!(:courses_user1) { create(:courses_user, course: course, user: user1) }
  let!(:courses_user2) { create(:courses_user, course: course, user: user2) }
  let!(:courses_user3) { create(:courses_user, course: course, user: user3) }
  let(:article) { create(:article, created_at: course.start + 10.minute, namespace: 0, deleted: false) }
  let!(:articles_course1) {
    create(:articles_course, article: article, course: course, user_ids: [user1.id], new_article: true, tracked: true)
  }
  let!(:articles_course2) {
    create(:articles_course, article: article, course: course, user_ids: [user2.id], new_article: false, tracked: true)
  }
  let(:subject) { described_class.new(course).generate_csv }

  it 'creates a CSV with a header and a row of data for each student' do
    lines = subject.split("\n")
    expect(lines.count).to eq(4)

    lines.shift # Remove headers

    expected_result = {
      'first_user' => { created: '1', updated: '1' },
      'second_user' => { created: '0', updated: '1' },
      'third_user' => { created: '0', updated: '0' }
    }

    lines.each do |line|
      columns = line.split(',')
      user_result = expected_result[columns[0]]
      # column 9 is 'registered_during_project', which should be true
      expect(columns[8]).to eq('true')
      expect(columns[9]).to eq(user_result[:created])
      expect(columns[10]).to eq(user_result[:updated])
    end
  end
end
