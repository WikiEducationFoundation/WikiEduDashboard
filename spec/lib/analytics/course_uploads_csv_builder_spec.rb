# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/analytics/course_uploads_csv_builder"

describe CourseUploadsCsvBuilder do
  let(:course) { create(:course) }
  let(:user) { create(:user) }
  let!(:courses_user) { create(:courses_user, course: course, user: user) }
  let(:upload_count) { 5 }
  let(:subject) { described_class.new(course).generate_csv }
  before do
    # Uploads during the course
    upload_count.times do |i|
      create(:commons_upload, file_name: "File:#{i}.gif", user: user,
                              uploaded_at: course.start + 1.minute)
    end
    # Upload outside the course
    create(:commons_upload, file_name: 'File:Nope.gif', user: user,
                            uploaded_at: course.start - 1.minute)
  end

  it 'creates a CSV with a header and a row of data for each course upload' do
    expect(subject.split("\n").count).to eq(upload_count + 1)
  end
end
