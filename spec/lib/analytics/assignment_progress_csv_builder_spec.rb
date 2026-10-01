# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/analytics/assignment_progress_csv_builder"

describe AssignmentProgressCsvBuilder do
  # Dated ahead, so nothing is overdue unless a spec travels there.
  let(:course) do
    create(:course, start: 1.week.from_now, end: 4.months.from_now,
                    timeline_start: 1.week.from_now, timeline_end: 4.months.from_now,
                    flags: { peer_review_count: 1 })
  end
  let(:week) { create(:week, course:, order: 0) }
  let(:zed) { create(:user, username: 'zed', real_name: 'Zed Real') }
  let(:amy) { create(:user, username: 'Amy') }
  let(:training) { create(:training_module, slug: 'tr-a', name: 'Training A', kind: 0) }
  let(:exercise) { create(:training_module, slug: 'ex-a', name: 'Exercise A', kind: 1) }
  let(:bibliography_exercise) do
    create(:training_module, slug: 'bib-ex', name: 'Bibliography exercise', kind: 1,
                             settings: { 'assignment_sandbox_location' => 'Bibliography' })
  end
  let(:presenter) { AssignmentProgressPresenter.new(course:) }
  let(:real_names) { false }
  let(:csv) { CSV.parse(described_class.new(presenter, real_names:).generate_csv, headers: true) }

  before do
    [zed, amy].each do |user|
      create(:courses_user, course:, user:, role: CoursesUsers::Roles::STUDENT_ROLE)
    end
    # Timeline order mixes the kinds: exercise, training, then the article's exercise.
    create(:block, week:, order: 0, training_module_ids: [exercise.id, training.id])
    create(:block, week:, order: 1, training_module_ids: [bibliography_exercise.id])
    create(:block, week:, order: 2, title: 'Peer review', training_module_ids: [])
  end

  def complete_exercise(user, mod)
    tmu = TrainingModulesUsers.create!(user:, training_module: mod)
    tmu.mark_completion(true, course.id)
    tmu.save!
  end

  it 'has one row per student, in username order' do
    expect(csv.map { |row| row['username'] }).to eq(%w[Amy zed])
  end

  it 'leads with the assigned article, then trainings, exercises and peer reviews' do
    statuses = csv.headers.select { |header| header.end_with?(': status') }
    expect(statuses).to eq(['Assigned article: status', 'Training A: status',
                            'Exercise A: status', 'Peer reviews: status'])
  end

  it 'gives each training and exercise its status, completion and whether it\'s overdue' do
    TrainingModulesUsers.create!(user: amy, training_module: training, completed_at: 1.day.ago)
    amy_row, zed_row = csv.map(&:to_h)
    expect(amy_row).to include('Training A: status' => 'complete', 'Training A: overdue' => 'false',
                               'Exercise A: status' => 'not_started')
    expect(amy_row['Training A: completed_at']).to be_present
    expect(zed_row).to include('Training A: status' => 'not_started',
                               'Training A: completed_at' => nil)
  end

  it 'marks unfinished assignments overdue once past due' do
    travel_to(presenter.item('training-tr-a').due_date + 1.day) do
      expect(csv.map { |row| row['Training A: overdue'] }).to eq(%w[true true])
    end
  end

  it 'gives the article\'s titles, the stages reached, and each exercise about it' do
    %w[First Second].each do |title|
      Assignment.create!(course:, user: amy, wiki: course.home_wiki,
                         role: Assignment::Roles::ASSIGNED_ROLE, article_title: title)
    end
    complete_exercise(amy, bibliography_exercise)
    amy_row = csv.first
    expect(amy_row['Assigned article: status']).to eq('in_progress')
    expect(amy_row['Assigned article: articles']).to eq('First; Second')
    expect(amy_row['Assigned article: bibliography_reached']).to eq('true')
    expect(amy_row['Assigned article: live_reached']).to eq('false')
    expect(amy_row['Assigned article: Bibliography exercise completed']).to eq('true')
    expect(csv.headers).not_to include('Assigned article: assigned_reached')
  end

  it 'counts the peer reviews each student has done' do
    expect(csv.map { |row| row['Peer reviews: reviews_completed'] }).to eq(%w[0 0])
  end

  it 'leaves out real names unless the viewer may see them' do
    expect(csv.headers).not_to include('real_name')
  end

  context 'when the viewer may see real names' do
    let(:real_names) { true }

    it 'gives each student\'s real name after their username' do
      expect(csv.headers.first(2)).to eq(%w[username real_name])
      expect(csv.map { |row| row['real_name'] }).to eq([nil, 'Zed Real'])
    end
  end
end
