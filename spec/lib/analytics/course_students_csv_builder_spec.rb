# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/analytics/course_students_csv_builder"

describe CourseStudentsCsvBuilder do
  let(:course) { create(:course) }
  let(:user1) { create(:user, registered_at: course.start + 1.minute, username: 'user1') }
  let(:user2) { create(:user, registered_at: course.start + 2.minutes, username: 'user2') }
  let(:user3) { create(:user, registered_at: course.start + 3.minutes, username: 'user3') }
  let!(:courses_user1) { create(:courses_user, course:, user: user1) }
  let!(:courses_user2) { create(:courses_user, course:, user: user2) }
  let!(:courses_user3) { create(:courses_user, course:, user: user3) }
  let(:article) do
    create(:article, created_at: course.start + 10.minutes, namespace: 0, deleted: false)
  end
  let!(:articles_course1) do
    create(:articles_course, article:, course:, user_ids: [user1.id, user2.id],
           new_article: true, tracked: true)
  end
  let!(:revision1) do
    create(:revision, article:, user: user1, new_article: true,
           date: course.start + 10.minutes)
  end
  let!(:revision2) do
    create(:revision, article:, user: user2, date: course.start + 15.minutes)
  end
  let(:subject) { described_class.new(course).generate_csv }

  it 'creates a CSV with a header and a row of data for each student' do
    lines = subject.split("\n")
    expect(lines.count).to eq(4)
    lines.shift # Remove headers

    expected_result = {
      'user1' => { articles_created: '1', articles_updated: '1' },
      'user2' => { articles_created: '0', articles_updated: '1' },
      'user3' => { articles_created: '0', articles_updated: '0' }
    }

    lines.each do |line|
      columns = line.split(',')
      username = columns[0]
      user_result = expected_result[username]
      # column 10 is 'registered_during_project', which should be true
      expect(columns[9]).to eq('true')
      # column 11 is 'total_articles_created'
      expect(columns[10]).to eq(user_result[:articles_created])
      # column 12 is 'total_articles_edited'
      expect(columns[11]).to eq(user_result[:articles_updated])
    end
  end
end
