# frozen_string_literal: true

require 'rails_helper'

describe PeerReviewAssignmentViewContext do
  let(:course) { create(:course, flags: { peer_review_count: 2 }) }
  let(:binding) do
    LtiCourseBinding.create!(
      course:, lms_id: 'platform-x', lms_family: 'canvas',
      lms_context_id: 'canvas-77', lms_resource_link_id: 'rl-99'
    )
  end
  let(:line_item) do
    LtiLineItem.create!(lti_course_binding: binding,
                        gradable_type: LtiLineItem::PEER_REVIEW_TYPE,
                        lineitem_id: 'https://lms/li/pr', label: 'Wikipedia peer review')
  end

  before { allow(LtiLineItemSyncWorker).to receive(:perform_in) }

  def link_student(user)
    LtiContext.create!(lti_course_binding: binding, user:,
                       user_lti_id: "lti-#{user.username}", lms_id: 'platform-x',
                       roles: ['vocab/membership#Learner'], linked_at: Time.current)
  end

  def assign_review(user, title, page: false)
    assignment = Assignment.create!(course:, user:, wiki: course.home_wiki,
                                    role: Assignment::Roles::REVIEWING_ROLE,
                                    article_title: title)
    if page
      assignment.update_sandbox_status(
        :review, AssignmentPipeline::SandboxStatuses::EXISTS_IN_USERSPACE
      )
    end
    assignment
  end

  it 'builds a roster row per linked student with reviews done out of expected' do
    done = create(:user, username: 'Done')
    partway = create(:user, username: 'Partway')
    none = create(:user, username: 'None')
    [done, partway, none].each { |user| link_student(user) }
    assign_review(done, 'Alpha', page: true)
    assign_review(done, 'Beta', page: true)
    assign_review(partway, 'Alpha', page: true)
    assign_review(partway, 'Gamma')

    roster = described_class.new(line_item:, user: done, instructor: true).roster
    expect(roster.map { |r| [r.name, r.completed_count, r.total_count, r.progress_state] })
      .to eq([['Done', 2, 2, :complete], ['None', 0, 2, :none], ['Partway', 1, 2, :partial]])
  end

  it 'lists each assigned review with its article, review page and completion' do
    student = create(:user, username: 'Reviewer')
    link_student(student)
    assign_review(student, 'Alpha_article', page: true)
    assign_review(student, 'Beta')

    reviews = described_class.new(line_item:, user: student, instructor: true)
                             .roster.first.reviews
    expect(reviews.map { |r| [r.article_title, r.completed?] })
      .to contain_exactly(['Alpha article', true], ['Beta', false])
    expect(reviews.map(&:review_url)).to all(include('Reviewer_Peer_Review'))
  end

  it 'leaves out learners who have not connected a Dashboard account' do
    linked = create(:user, username: 'Linked')
    link_student(linked)
    LtiContext.create!(lti_course_binding: binding, user: nil, user_lti_id: 'lti-nobody',
                       lms_id: 'platform-x', roles: ['vocab/membership#Learner'])

    roster = described_class.new(line_item:, user: linked, instructor: true).roster
    expect(roster.map(&:name)).to eq(['Linked'])
  end

  it 'narrows the roster to the focus user for a submission launch' do
    first = create(:user, username: 'First')
    second = create(:user, username: 'Second')
    [first, second].each { |user| link_student(user) }

    roster = described_class.new(line_item:, user: first, instructor: true,
                                 focus_user: second).roster
    expect(roster.map(&:name)).to eq(['Second'])
  end

  it 'builds the launching student\'s own row and review list' do
    student = create(:user, username: 'Solo')
    link_student(student)
    assign_review(student, 'Alpha', page: true)

    context = described_class.new(line_item:, user: student, instructor: false)
    row = context.student_panel
    expect([row.name, row.completed_count, row.total_count, row.done?])
      .to eq(['Solo', 1, 2, false])
    expect(context.viewer_review_rows.map(&:article_title)).to eq(['Alpha'])
  end

  it 'reports the course\'s expected review count' do
    student = create(:user, username: 'Solo')
    link_student(student)

    expect(described_class.new(line_item:, user: student, instructor: false).expected_count)
      .to eq(2)
  end
end
