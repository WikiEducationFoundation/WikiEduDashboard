# frozen_string_literal: true

require 'rails_helper'

describe ArticleFunnel do
  let(:course) do
    create(:course, start: 1.week.from_now, end: 4.months.from_now,
                    timeline_start: 1.week.from_now, timeline_end: 4.months.from_now)
  end
  let(:week) { create(:week, course:, order: 1) }
  let(:amy) { create(:user, username: 'Amy') }
  let(:bo) { create(:user, username: 'Bo') }
  let(:cy) { create(:user, username: 'Cy') }
  let(:bibliography_exercise) do
    create(:training_module, slug: 'bib-ex', kind: 1,
                             settings: { 'assignment_sandbox_location' => 'Bibliography' })
  end

  before do
    [amy, bo, cy].each do |user|
      create(:courses_user, course:, user:, role: CoursesUsers::Roles::STUDENT_ROLE)
    end
  end

  def funnel(for_course = course)
    AssignmentProgressPresenter.new(course: for_course).article_funnel
  end

  def stage(key, for_course = course)
    funnel(for_course)[:stages].find { |s| s[:key] == key }
  end

  def assign(user, title)
    Assignment.create!(course:, user:, wiki: course.home_wiki,
                       role: Assignment::Roles::ASSIGNED_ROLE, article_title: title)
  end

  it 'counts the students who have reached each stage, out of the whole class' do
    first = assign(amy, 'First')
    assign(bo, 'Second')
    first.update_sandbox_status(:draft, AssignmentPipeline::SandboxStatuses::EXISTS_IN_USERSPACE)

    expect(funnel[:total]).to eq(3)
    expect(funnel[:stages].map { |s| [s[:key], s[:reached]] })
      .to eq([[:assigned, 2], [:bibliography, 0], [:outline, 0], [:draft, 1], [:live, 0]])
  end

  it 'counts a student once any of their articles reaches a stage' do
    assign(amy, 'First')
    second = assign(amy, 'Second')
    second.update_sandbox_status(:bibliography,
                                 AssignmentPipeline::SandboxStatuses::EXISTS_IN_USERSPACE)
    expect(stage(:bibliography)[:reached]).to eq(1)
  end

  it 'drops the draft without sandboxes, and bibliography and outline outside classrooms' do
    course.update!(flags: { no_sandboxes: true })
    expect(funnel[:stages].map { |s| s[:key] }).to eq(%i[assigned bibliography outline live])

    fellows = create(:fellows_cohort)
    expect(funnel(fellows)[:stages].map { |s| s[:key] }).to eq(%i[assigned draft live])
  end

  it 'takes a stage\'s due date from its exercise, and counts who is overdue past it' do
    create(:block, week:, order: 0, training_module_ids: [bibliography_exercise.id])
    first = assign(amy, 'First')
    first.update_sandbox_status(:bibliography,
                                AssignmentPipeline::SandboxStatuses::EXISTS_IN_USERSPACE)
    due = stage(:bibliography)[:due_date]
    expect(due).to eq(course.blocks.first.calculated_due_date)
    expect(stage(:bibliography)).not_to have_key(:overdue)

    travel_to(due + 1.day) { expect(stage(:bibliography)[:overdue]).to eq(2) }
  end
end
