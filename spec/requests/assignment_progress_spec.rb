# frozen_string_literal: true

require 'rails_helper'

describe 'Assignment progress', type: :request do
  # Dated ahead, so nothing is overdue unless a spec travels there.
  let(:course) do
    create(:course, slug: 'School/Assignments_(Fall_2026)', start: 1.week.from_now,
                    end: 4.months.from_now, timeline_start: 1.week.from_now,
                    timeline_end: 4.months.from_now)
  end
  let(:instructor) { create(:user, username: 'Prof') }
  let(:student) { create(:user, username: 'Student') }
  let(:week) { create(:week, course:, order: 0) }
  let(:training) { create(:training_module, slug: 'tr-a', name: 'Training A', kind: 0) }
  let(:path) { "/courses/#{course.slug}/assignment_progress.json" }

  before do
    create(:courses_user, course:, user: instructor, role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    create(:courses_user, course:, user: student, role: CoursesUsers::Roles::STUDENT_ROLE)
    create(:block, week:, order: 0, training_module_ids: [training.id])
  end

  def body
    JSON.parse(response.body)
  end

  context 'as the instructor' do
    before { login_as instructor }

    it 'returns the students, assignments and summary' do
      get path
      expect(response.status).to eq(200)
      expect(body['students'].map { |s| s['username'] }).to eq(['Student'])
      expect(body['items'].first).to include('key' => 'training-tr-a', 'kind' => 'training',
                                             'title' => 'Training A')
      expect(body['summary'].first).to include('key' => 'training-tr-a', 'not_started' => 1)
      expect(body).not_to have_key('rows')
    end

    it 'returns one assignment\'s rows when asked' do
      get path, params: { item: 'training-tr-a' }
      expect(body['item_key']).to eq('training-tr-a')
      expect(body['rows']).to eq([{ 'user_id' => student.id, 'state' => 'not_started' }])
    end

    it 'is not found for an unknown assignment' do
      get path, params: { item: 'training-nope' }
      expect(response.status).to eq(404)
    end

    it 'serves a Fellows cohort' do
      course.update!(type: 'FellowsCohort')
      get path
      expect(response.status).to eq(200)
    end

    it 'is not found for a course type without the tab' do
      course.update!(type: 'BasicCourse')
      get path
      expect(response.status).to eq(404)
    end

    it 'takes the same number of queries however many students there are' do
      count_queries = lambda do
        counted = 0
        subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |*, payload|
          counted += 1 unless %w[SCHEMA TRANSACTION].include?(payload[:name])
        end
        get path, params: { item: 'article' }
        ActiveSupport::Notifications.unsubscribe(subscriber)
        counted
      end
      Assignment.create!(course:, user: student, wiki: course.home_wiki,
                         role: Assignment::Roles::ASSIGNED_ROLE, article_title: 'Art')
      count_queries.call # warm up one-time lookups
      with_one = count_queries.call
      3.times do |i|
        user = create(:user, username: "More#{i}")
        create(:courses_user, course:, user:, role: CoursesUsers::Roles::STUDENT_ROLE)
        Assignment.create!(course:, user:, wiki: course.home_wiki,
                           role: Assignment::Roles::ASSIGNED_ROLE, article_title: "Art_#{i}")
      end
      expect(count_queries.call).to eq(with_one)
    end
  end

  it 'refuses a student' do
    login_as student
    get path
    expect(response.status).to eq(401)
  end

  it 'refuses a visitor who is not signed in' do
    get path
    expect(response.status).to eq(401)
  end
end
