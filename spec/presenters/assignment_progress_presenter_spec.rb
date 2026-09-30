# frozen_string_literal: true

require 'rails_helper'

describe AssignmentProgressPresenter do
  # Dated ahead, so nothing is overdue unless a spec travels there.
  let(:course) do
    create(:course, start: 1.week.from_now, end: 4.months.from_now,
                    timeline_start: 1.week.from_now, timeline_end: 4.months.from_now)
  end
  let(:week) { create(:week, course:, order: 0) }
  let(:zed) { create(:user, username: 'zed') }
  let(:amy) { create(:user, username: 'Amy') }
  let(:training) { create(:training_module, slug: 'tr-a', kind: 0, slide_slugs: %w[a b]) }
  let(:exercise) do
    create(:training_module, slug: 'ex-a', kind: 1,
                             settings: { 'sandbox_location' => 'Evaluate_an_Article' })
  end
  let(:presenter) { described_class.new(course:) }

  before do
    [zed, amy].each do |user|
      create(:courses_user, course:, user:, role: CoursesUsers::Roles::STUDENT_ROLE)
    end
    create(:courses_user, course:, user: create(:user, username: 'Prof'),
                          role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    create(:block, week:, order: 0, training_module_ids: [training.id, exercise.id])
  end

  def rows(key)
    presenter.rows_for(presenter.item(key))
  end

  def assign(user, title)
    Assignment.create!(course:, user:, wiki: course.home_wiki,
                       role: Assignment::Roles::ASSIGNED_ROLE, article_title: title)
  end

  it 'lists the students, not other roles, by username' do
    expect(presenter.students.map(&:username)).to eq(%w[Amy zed])
  end

  it 'reports training completion, progress and time per student' do
    completed_at = Time.zone.parse('2026-01-06 09:00')
    TrainingModulesUsers.create!(user: amy, training_module: training, completed_at:)
    TrainingModulesUsers.create!(user: zed, training_module: training, last_slide_completed: 'a')

    expect(rows('training-tr-a')).to eq([
      { user_id: amy.id, state: 'complete', completed_at:, slide_progress: 1.0 },
      { user_id: zed.id, state: 'in_progress', slide_progress: 0.5 }
    ])
  end

  it 'marks students overdue once an unfinished module is past due' do
    due = presenter.item('training-tr-a').due_date
    travel_to(due + 1.day) do
      expect(rows('training-tr-a').map { |row| row[:overdue] }).to eq([true, true])
    end
  end

  it 'marks peer reviews overdue once the peer-review block is past due' do
    course.update!(flags: { peer_review_count: 1 })
    create(:block, week:, order: 1, title: 'Peer review an article', training_module_ids: [])
    travel_to(presenter.item('peer-review').due_date + 1.day) do
      expect(rows('peer-review').map { |row| row[:overdue] }).to eq([true, true])
    end
  end

  it 'reports exercise completion with each student\'s sandbox and no invented time' do
    tmu = TrainingModulesUsers.create!(user: amy, training_module: exercise,
                                       completed_at: 1.day.ago)
    tmu.mark_completion(true, course.id)
    tmu.save!

    amy_row = rows('exercise-ex-a').first
    expect(amy_row[:state]).to eq('complete')
    expect(amy_row).not_to have_key(:completed_at)
    expect(amy_row[:sandbox_url]).to end_with('User:Amy/Evaluate_an_Article')
  end

  it 'gives each assigned article its own entry, completing the student when all are done' do
    first = assign(amy, 'First')
    assign(amy, 'Second')
    first.update_sandbox_status(:bibliography,
                                AssignmentPipeline::SandboxStatuses::EXISTS_IN_USERSPACE)

    amy_row, zed_row = rows('article-bibliography')
    expect(amy_row[:state]).to eq('in_progress')
    expect(amy_row[:articles].map { |a| [a[:title], a[:complete]] })
      .to eq([['First', true], ['Second', false]])
    expect(zed_row).to eq(user_id: zed.id, state: 'not_started', articles: [])
  end

  it 'counts a bibliography marked done in the pipeline even without the page' do
    assign(amy, 'First').update_status(AssignmentPipeline::AssignmentStatuses::IN_PROGRESS)
    expect(rows('article-bibliography').first[:state]).to eq('complete')
  end

  it 'counts live-article work once the student has edits in it' do
    article = create(:article, title: 'First', wiki: course.home_wiki)
    assign(amy, 'First').update!(article:)
    ArticleCourseTimeslice.create!(course:, article:, user_ids: [amy.id], revision_count: 3,
                                   start: 2.days.ago, end: 1.day.ago)

    expect(rows('article-live').first[:state]).to eq('complete')
    expect(rows('article-live').first[:articles].first[:stats][:revisions]).to eq(3)
  end

  it 'measures peer reviews against the assigned ones when the course sets no count' do
    review = Assignment.create!(course:, user: amy, wiki: course.home_wiki,
                                role: Assignment::Roles::REVIEWING_ROLE, article_title: 'Theirs')
    review.update_status(AssignmentPipeline::ReviewStatuses::PEER_REVIEW_COMPLETED)

    amy_row = rows('peer-review').first
    expect(amy_row).to include(state: 'complete', completed_count: 1)
    expect(amy_row).not_to have_key(:expected)
  end

  it 'summarizes each assignment by state' do
    TrainingModulesUsers.create!(user: amy, training_module: training, completed_at: 1.day.ago)
    summary = presenter.summary.find { |row| row[:key] == 'training-tr-a' }
    expect(summary).to include(complete: 1, in_progress: 0, not_started: 1, total: 2)
  end

  it 'links module assignments to their training page' do
    expect(presenter.links_for(presenter.item('exercise-ex-a'))[:training_url])
      .to include('/training/')
    expect(presenter.links_for(presenter.item('article-live'))).to eq({})
  end
end
