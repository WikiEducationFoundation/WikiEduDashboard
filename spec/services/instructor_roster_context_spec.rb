# frozen_string_literal: true

require 'rails_helper'

describe InstructorRosterContext do
  let(:course) { create(:course, slug: 'School/Course_(Term)') }
  let(:binding) do
    LtiCourseBinding.create!(course:, lms_id: 'canvas-guid', lms_family: 'canvas',
                             lms_context_id: 'ctx-11', lms_resource_link_id: 'rl-11',
                             lti_version: '1.2.0')
  end
  let(:launched) { create(:user, username: 'Zoe_Launched') }
  let(:passcode) { create(:user, username: 'adam_Passcode') }
  let(:instructor) { create(:user, username: 'Prof') }

  subject(:roster) { described_class.new(binding:) }

  before do
    CoursesUsers.create!(course:, user: launched, role: CoursesUsers::Roles::STUDENT_ROLE,
                         revision_count: 12, character_sum_ms: 3400, references_count: 5)
    CoursesUsers.create!(course:, user: passcode, role: CoursesUsers::Roles::STUDENT_ROLE)
    CoursesUsers.create!(course:, user: instructor, role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    LtiContext.create!(user: launched, lti_course_binding: binding, user_lti_id: 'lti-zoe',
                       lms_id: 'canvas-guid', roles: ['Learner'], linked_at: 1.hour.ago)
    LtiContext.create!(user: instructor, lti_course_binding: binding, user_lti_id: 'lti-prof',
                       lms_id: 'canvas-guid', roles: ['Instructor'], linked_at: 2.hours.ago)
  end

  it 'lists every enrolled student, sorted by username regardless of case' do
    expect(roster.rows.map(&:username)).to eq(%w[adam_Passcode Zoe_Launched])
  end

  it 'leaves the instructor out' do
    expect(roster.rows.map(&:username)).not_to include('Prof')
  end

  # Enrollment is the basis, not launches: the passcode student is listed, and
  # only the one with a linked launch context is marked connected.
  it 'marks the student who launched from Canvas and not the one who joined by passcode' do
    expect(roster.rows.map(&:connected)).to eq([false, true])
  end

  it 'carries the edit statistics from the course roster' do
    zoe = roster.rows.last
    expect([zoe.revision_count, zoe.character_sum_ms, zoe.references_count]).to eq([12, 3400, 5])
  end

  it 'links to the student details page' do
    expect(roster.rows.first.details_url)
      .to eq('/courses/School/Course_(Term)/students/articles/adam_Passcode')
  end

  it 'builds the same overview a student sees, and their peer-review progress' do
    zoe = roster.rows.last
    expect(zoe.status).to be_a(StudentStatusContext)
    expect(zoe.status.user).to eq(launched)
    expect(zoe.peer_review_progress).to be_a(LtiPeerReviewProgress)
    expect(zoe.peer_reviews).to eq([])
  end

  it 'is empty for a course with no students' do
    CoursesUsers.where(role: CoursesUsers::Roles::STUDENT_ROLE).delete_all
    expect(roster).to be_empty
  end

  # The wizard's "0 peer reviews" choice sets no flag, the same as a course that
  # never reached that question; only a positive count means the stage exists.
  # LtiPeerReviewProgress falls back to one review when the flag is unset, so
  # without this gate the roster would read "0 / 1" for a course with none.
  describe '#peer_reviews_expected?' do
    it 'is false when the course never set a peer-review count' do
      expect(course.peer_review_count).to be_nil
      expect(roster).not_to be_peer_reviews_expected
    end

    it 'is false when the course expects zero reviews' do
      course.update!(flags: { peer_review_count: 0 })
      expect(roster).not_to be_peer_reviews_expected
    end

    it 'is true when the wizard set a reviewer count' do
      course.update!(flags: { peer_review_count: 2 })
      expect(roster).to be_peer_reviews_expected
    end
  end

  # One instructor launch reads every student's state. Fetching per student made
  # the page's cost grow with the class; the roster now loads the course
  # structure and every student's completions and assignments up front.
  describe 'query cost' do
    let(:week) { create(:week, course:, order: 0) }
    let(:training) { create(:training_module, slug: 'tr-a', name: 'Training', kind: 0) }
    let(:exercise) do
      create(:training_module, slug: 'ex-a', name: 'Exercise', kind: 1,
                               settings: { 'sandbox_location' => 'A' })
    end

    before do
      create(:block, week:, order: 0, title: 'Trainings', training_module_ids: [training.id])
      create(:block, week:, order: 1, title: 'Exercise', training_module_ids: [exercise.id])
      enroll_with_work(launched)
    end

    def enroll_with_work(user)
      TrainingModulesUsers.create!(user:, training_module: training, completed_at: 1.day.ago)
      Assignment.create!(course:, user:, wiki: course.home_wiki,
                         role: Assignment::Roles::ASSIGNED_ROLE, article_title: 'Ada_Lovelace')
      Assignment.create!(course:, user:, wiki: course.home_wiki,
                         role: Assignment::Roles::REVIEWING_ROLE, article_title: 'Grace_Hopper')
    end

    def queries_to_read_the_roster
      count = 0
      subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |*, payload|
        count += 1 unless %w[SCHEMA TRANSACTION].include?(payload[:name])
      end
      described_class.new(binding:).rows.each do |row|
        status = row.status
        [status.trainings_completed, status.exercises_completed, status.next_step,
         status.articles.map(&:sandbox_url), row.peer_review_progress.completed_count,
         row.peer_reviews.map(&:review_url)]
      end
      count
    ensure
      ActiveSupport::Notifications.unsubscribe(subscriber)
    end

    it 'does not grow with the number of students' do
      with_two = queries_to_read_the_roster
      4.times do |i|
        student = create(:user, username: "Student #{i}")
        CoursesUsers.create!(course:, user: student, role: CoursesUsers::Roles::STUDENT_ROLE)
        enroll_with_work(student)
      end
      expect(queries_to_read_the_roster).to eq(with_two)
    end
  end
end
