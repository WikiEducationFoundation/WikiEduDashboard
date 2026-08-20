# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/analytics/mentor_requests_csv_builder"

describe MentorRequestsCsvBuilder do
  let(:campaign) { create(:campaign) }
  let(:course) do
    create(:course, title: 'Chem 101', school: 'Test University', term: 'Fall 2026',
                    subject: 'Chemistry', slug: 'Test_University/Chem_101_(Fall_2026)')
  end
  let(:instructor) do
    create(:user, username: 'chem_instructor', real_name: 'Onboarding Name',
                  email: 'chem@example.edu')
  end

  let(:csv) { described_class.new(campaign).generate_csv }
  let(:lines) { csv.split("\n") }

  before do
    create(:campaigns_course, campaign_id: campaign.id, course_id: course.id)
    create(:tag, course_id: course.id, tag: 'mentor_requested', key: 'mentoring')
    create(:courses_user, course_id: course.id, user_id: instructor.id,
                          role: CoursesUsers::Roles::INSTRUCTOR_ROLE,
                          real_name: 'Enrollment Name')
  end

  it 'includes the expected headers' do
    expect(lines.first).to eq(described_class::CSV_HEADERS.join(','))
  end

  it 'includes a row for the instructor of a tagged campaign course' do
    expect(lines.second.split(',')).to eq(['Enrollment Name', 'chem_instructor',
                                           'chem@example.edu', 'Test University', 'Chem 101',
                                           'Chemistry', 'Fall 2026', course.slug])
  end

  it 'includes one row per co-instructor' do
    co_instructor = create(:user, username: 'co_instructor')
    create(:courses_user, course_id: course.id, user_id: co_instructor.id,
                          role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    expect(lines.count).to eq(3)
    expect(csv).to include('co_instructor')
  end

  it 'excludes students of tagged courses' do
    student = create(:user, username: 'student_user')
    create(:courses_user, course_id: course.id, user_id: student.id,
                          role: CoursesUsers::Roles::STUDENT_ROLE)
    expect(csv).not_to include('student_user')
  end

  it 'excludes untagged courses in the campaign' do
    untagged_course = create(:course, title: 'Bio 101', slug: 'Test_University/Bio_101')
    create(:campaigns_course, campaign_id: campaign.id, course_id: untagged_course.id)
    other_instructor = create(:user, username: 'untagged_instructor')
    create(:courses_user, course_id: untagged_course.id, user_id: other_instructor.id,
                          role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    expect(csv).not_to include('untagged_instructor')
  end

  it 'excludes tagged courses outside the campaign' do
    outside_course = create(:course, title: 'Phys 101', slug: 'Test_University/Phys_101')
    create(:tag, course_id: outside_course.id, tag: 'mentor_requested', key: 'mentoring')
    outside_instructor = create(:user, username: 'outside_instructor')
    create(:courses_user, course_id: outside_course.id, user_id: outside_instructor.id,
                          role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    expect(csv).not_to include('outside_instructor')
  end

  it 'falls back to the user real_name, then username' do
    CoursesUsers.find_by(user_id: instructor.id).update(real_name: nil)
    expect(lines.second).to start_with('Onboarding Name')

    instructor.update(real_name: nil)
    fresh_csv = described_class.new(campaign).generate_csv
    expect(fresh_csv.split("\n").second).to start_with('chem_instructor')
  end
end
