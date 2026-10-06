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

  describe 'the CSV' do
    let(:csv_path) { "/courses/#{course.slug}/assignment_progress.csv" }

    before { student.update!(real_name: 'Stu Dent') }

    it 'downloads every student\'s statuses, one row per student, with real names' do
      login_as instructor
      get csv_path
      expect(response.status).to eq(200)
      expect(response.media_type).to eq('text/csv')
      expect(response.headers['Content-Disposition'])
        .to start_with('attachment').and include("-assignments-#{Time.zone.today}.csv")
      rows = CSV.parse(response.body, headers: true)
      expect(rows.map(&:to_h)).to eq([{ 'username' => 'Student', 'real_name' => 'Stu Dent',
                                        'Assigned article: status' => 'not_started',
                                        'Assigned article: overdue' => 'false',
                                        'Assigned article: articles' => nil,
                                        'Assigned article: bibliography_reached' => 'false',
                                        'Assigned article: outline_reached' => 'false',
                                        'Assigned article: draft_reached' => 'false',
                                        'Assigned article: live_reached' => 'false',
                                        'Training A: status' => 'not_started',
                                        'Training A: overdue' => 'false',
                                        'Training A: completed_at' => nil }])
    end

    it 'is not found for a course type without the tab' do
      course.update!(type: 'BasicCourse')
      login_as instructor
      get csv_path
      expect(response.status).to eq(404)
    end

    it 'refuses a student' do
      login_as student
      get csv_path
      expect(response.status).to eq(401)
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
