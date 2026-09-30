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
  let(:bibliography_exercise) do
    create(:training_module, slug: 'bib-ex', name: 'Bibliography', kind: 1,
                             settings: { 'assignment_sandbox_location' => 'Bibliography' })
  end
  let(:presenter) { described_class.new(course:) }

  before do
    [zed, amy].each do |user|
      create(:courses_user, course:, user:, role: CoursesUsers::Roles::STUDENT_ROLE)
    end
    create(:courses_user, course:, user: create(:user, username: 'Prof'),
                          role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    create(:block, week:, order: 0, training_module_ids: [training.id, exercise.id])
    create(:block, week:, order: 1, training_module_ids: [bibliography_exercise.id])
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
    create(:block, week:, order: 2, title: 'Peer review an article', training_module_ids: [])
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

  def bibliography_due
    Block.find_by(week:, order: 1).calculated_due_date
  end

  def complete_exercise(user, mod)
    tmu = TrainingModulesUsers.create!(user:, training_module: mod)
    tmu.mark_completion(true, course.id)
    tmu.save!
  end

  def edit_live(assignment, revisions)
    article = create(:article, title: assignment.article_title, wiki: course.home_wiki)
    assignment.update!(article:)
    ArticleCourseTimeslice.create!(course:, article:, user_ids: [assignment.user_id],
                                   revision_count: revisions, start: 2.days.ago, end: 1.day.ago)
  end

  it 'shows each assigned article with its pages, and the article exercises as a checklist' do
    first = assign(amy, 'First')
    assign(amy, 'Second')
    first.update_sandbox_status(:bibliography,
                                AssignmentPipeline::SandboxStatuses::EXISTS_IN_USERSPACE)

    amy_row, zed_row = rows('article')
    expect(amy_row[:state]).to eq('in_progress')
    expect(amy_row[:articles].map { |a| a[:title] }).to eq(%w[First Second])
    bibliography = amy_row[:articles].first[:pages].find { |page| page[:kind] == :bibliography }
    expect(bibliography[:created]).to be(true)
    expect(amy_row[:exercises]).to eq([{ slug: 'bib-ex', name: 'Bibliography', completed: false,
                                         due_date: bibliography_due }])
    expect(zed_row).to include(state: 'not_started', articles: [])
  end

  it 'completes the article once its exercises are done and every article has live edits' do
    first = assign(amy, 'First')
    complete_exercise(amy, bibliography_exercise)
    expect(rows('article').first[:state]).to eq('in_progress')

    edit_live(first, 3)
    fresh = described_class.new(course:)
    amy_row = fresh.rows_for(fresh.item('article')).first
    expect(amy_row[:state]).to eq('complete')
    expect(amy_row[:articles].first[:stats][:revisions]).to eq(3)
    expect(amy_row[:exercises].first[:completed]).to be(true)
  end

  it 'marks the article overdue while one of its exercises is past due' do
    assign(amy, 'First')
    travel_to(bibliography_due + 1.day) do
      amy_row = rows('article').first
      expect(amy_row[:overdue]).to be(true)
      expect(amy_row[:exercises].first[:overdue]).to be(true)
    end
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
    expect(presenter.links_for(presenter.item('article'))).to eq({})
  end
end
