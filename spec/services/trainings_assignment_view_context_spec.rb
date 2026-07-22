# frozen_string_literal: true

require 'rails_helper'

describe TrainingsAssignmentViewContext do
  let(:course) { create(:course) }
  let(:week) { create(:week, course:, order: 1) }
  let(:training_a) { create(:training_module, slug: 'tr-a', name: 'A', kind: 0) }
  let(:training_b) { create(:training_module, slug: 'tr-b', name: 'B', kind: 0) }
  let(:binding) do
    LtiCourseBinding.create!(
      course:, lms_id: 'platform-x', lms_family: 'canvas',
      lms_context_id: 'canvas-77', lms_resource_link_id: 'rl-99'
    )
  end
  let(:line_item) do
    LtiLineItem.create!(lti_course_binding: binding,
                        gradable_type: LtiLineItem::TRAINING_PROGRESS_TYPE,
                        lineitem_id: 'https://lms/li/tr', label: 'Wikipedia trainings')
  end

  before do
    allow(LtiLineItemSyncWorker).to receive(:perform_in)
    create(:block, week:, order: 0, title: 'Trainings',
                   training_module_ids: [training_a.id, training_b.id])
  end

  def link_student(user, name: nil)
    LtiContext.create!(lti_course_binding: binding, user:, name:,
                       user_lti_id: "lti-#{user.username}", lms_id: 'platform-x',
                       roles: ['vocab/membership#Learner'], linked_at: Time.current)
  end

  it 'builds a roster row per linked student with their completed-trainings count' do
    done = create(:user, username: 'Done')
    partway = create(:user, username: 'Partway')
    link_student(done)
    link_student(partway)
    [training_a, training_b].each do |mod|
      TrainingModulesUsers.create!(user: done, training_module: mod, completed_at: 1.day.ago)
    end
    TrainingModulesUsers.create!(user: partway, training_module: training_a,
                                 completed_at: 1.day.ago)

    context = described_class.new(line_item:, user: done, instructor: true)
    expect(context.roster.map { |r| [r.name, r.completed_count, r.total_count, r.done?] })
      .to contain_exactly(['Done', 2, 2, true], ['Partway', 1, 2, false])
  end

  it 'builds the launching student\'s own panel row' do
    student = create(:user, username: 'Solo')
    link_student(student)
    TrainingModulesUsers.create!(user: student, training_module: training_b,
                                 completed_at: 1.day.ago)

    row = described_class.new(line_item:, user: student, instructor: false).student_panel
    expect(row.name).to eq('Solo')
    expect(row.completed_count).to eq(1)
    expect(row.total_count).to eq(2)
    expect(row.done?).to be(false)
  end

  it 'builds the student module table with due dates, statuses, and training links' do
    student = create(:user, username: 'Tabler')
    link_student(student)
    TrainingModulesUsers.create!(user: student, training_module: training_a,
                                 completed_at: 1.day.ago)

    rows = described_class.new(line_item:, user: student, instructor: false)
                          .viewer_training_rows
    expect(rows.map(&:name)).to contain_exactly('A', 'B')
    row_a = rows.find { |r| r.name == 'A' }
    expect(row_a.completed?).to be(true)
    expect(row_a.completion_date).to be_within(1.hour).of(1.day.ago)
    expect(row_a.training_url).to eq(
      "/training/#{course.training_library_slug}/tr-a" \
      "?return_to=#{CGI.escape("/courses/#{course.slug}")}"
    )
    expect(rows.find { |r| r.name == 'B' }.completed?).to be(false)
  end

  it 'reports per-module completion counts across connected students' do
    done = create(:user, username: 'Done')
    partway = create(:user, username: 'Partway')
    link_student(done)
    link_student(partway)
    [training_a, training_b].each do |mod|
      TrainingModulesUsers.create!(user: done, training_module: mod, completed_at: 1.day.ago)
    end
    TrainingModulesUsers.create!(user: partway, training_module: training_a,
                                 completed_at: 1.day.ago)

    stats = described_class.new(line_item:, user: done, instructor: true).module_stats
    expect(stats.map { |s| [s.name, s.completed_count, s.total_count] })
      .to contain_exactly(['A', 2, 2], ['B', 1, 2])
    expect(stats.first.training_url).to include('/training/')
  end

  it 'excludes instructor memberships from the roster' do
    prof = create(:user, username: 'Prof')
    LtiContext.create!(lti_course_binding: binding, user: prof, user_lti_id: 'lti-prof',
                       lms_id: 'platform-x', roles: ['vocab/membership#Instructor'],
                       linked_at: Time.current)

    context = described_class.new(line_item:, user: prof, instructor: true)
    expect(context.roster).to be_empty
  end
end
