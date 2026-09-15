# frozen_string_literal: true

require 'rails_helper'

# Privacy mode works by storing obfuscated values in `courses.title` and
# `courses.school`, so every downstream surface is anonymous by construction
# rather than by per-site masking. This spec is what keeps that true: it asks
# every course-facing endpoint for a privacy-mode course and asserts the real
# values never come back.
#
# If a future change starts serializing ConfidentialCourseDetail into a course
# payload, or reintroduces the real title somewhere, this fails.
describe 'Privacy-mode course confidentiality', type: :request do
  let(:wiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
  let(:real_title) { 'ZZTITLESENTINEL' }
  let(:real_school) { 'ZZSCHOOLSENTINEL' }
  let(:instructor) do
    create(:user, username: 'Instructor', email: 'zzemailsentinel@example.edu',
                  real_name: 'ZZNAMESENTINEL')
  end
  let(:student) { create(:user, username: 'Student') }
  let(:course) do
    create(:course, home_wiki: wiki, title: 'Course 1', school: 'Confidential',
                    term: 'Fall 2026', slug: 'Confidential/Course_1_(Fall_2026)',
                    start: 1.month.ago, end: 1.month.from_now)
  end

  # Every sentinel that must not reach a non-admin.
  let(:sentinels) do
    ['ZZTITLESENTINEL', 'ZZSCHOOLSENTINEL', 'ZZNAMESENTINEL', 'zzemailsentinel@example.edu']
  end

  let(:endpoints) do
    ["/courses/#{course.slug}",
     "/courses/#{course.slug}/course.json",
     "/courses/#{course.slug}/users.json",
     "/courses/#{course.slug}/articles.json",
     "/courses/#{course.slug}/campaigns.json",
     "/courses/#{course.slug}/timeline.json",
     "/courses/#{course.slug}/alerts.json",
     "/courses/#{course.slug}/tags.json",
     '/explore',
     "/courses/search.json?search=#{real_school}",
     "/courses/search.json?search=#{real_title}"]
  end

  before do
    create(:confidential_course_detail, course:, real_title:, real_school:)
    create(:courses_user, course:, user: instructor,
                          role: CoursesUsers::Roles::INSTRUCTOR_ROLE,
                          real_name: 'ZZNAMESENTINEL')
    create(:courses_user, course:, user: student, role: CoursesUsers::Roles::STUDENT_ROLE)
  end

  def expect_no_sentinels_from(endpoints)
    endpoints.each do |path|
      get path
      next unless response.successful?
      sentinels.each do |sentinel|
        expect(response.body).not_to include(sentinel), "#{sentinel} leaked from #{path}"
      end
    end
  end

  context 'when logged out' do
    it 'leaks no confidential value from any course endpoint' do
      expect_no_sentinels_from(endpoints)
    end
  end

  context 'when signed in as an enrolled student' do
    before { login_as student }

    it 'leaks no confidential value from any course endpoint' do
      expect_no_sentinels_from(endpoints)
    end
  end

  context 'when signed in as the course instructor' do
    before { login_as instructor }

    it 'leaks no confidential value from any course endpoint' do
      expect_no_sentinels_from(endpoints)
    end
  end

  it 'does not surface the course in a search for the real institution' do
    get "/courses/search.json?search=#{real_school}"
    expect(response.body).not_to include(course.slug)
  end

  it 'keeps the real values reachable for admins through the detail record' do
    detail = course.reload.confidential_course_detail
    expect(detail.real_title).to eq(real_title)
    expect(detail.real_school).to eq(real_school)
  end
end
