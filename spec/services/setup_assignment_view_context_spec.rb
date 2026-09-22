# frozen_string_literal: true

require 'rails_helper'

describe SetupAssignmentViewContext do
  let(:course) { create(:course) }
  let(:binding) do
    LtiCourseBinding.create!(
      course:, lms_id: 'platform-x', lms_family: 'canvas',
      lms_context_id: 'canvas-77', lms_resource_link_id: 'rl-99'
    )
  end
  let(:line_item) do
    LtiLineItem.create!(lti_course_binding: binding,
                        gradable_type: LtiLineItem::SETUP_TYPE,
                        lineitem_id: 'https://lms/li/setup', label: 'Wikipedia account')
  end
  let(:context) { described_class.new(line_item:, instructor: true) }

  # Anonymized mode: LtiContext carries no name, so a pending member has no
  # legible identity at all until they connect a Wikipedia account.
  def student_context(user_lti_id:, user: nil, status: nil)
    LtiContext.create!(lti_course_binding: binding, user_lti_id:, user:,
                       lms_id: 'platform-x', roles: ['vocab/membership#Learner'],
                       linked_at: user && Time.current, lms_membership_status: status)
  end

  def enroll(user, real_name:)
    CoursesUsers.create!(user:, course:, role: CoursesUsers::Roles::STUDENT_ROLE,
                         real_name:)
  end

  it 'lists the connected students by name' do
    zoe = create(:user, username: 'WikiZoe')
    anna = create(:user, username: 'WikiAnna')
    enroll(zoe, real_name: 'Zoe Real')
    enroll(anna, real_name: 'Anna Real')
    student_context(user_lti_id: 'lti-1', user: zoe)
    student_context(user_lti_id: 'lti-2', user: anna)
    student_context(user_lti_id: 'lti-3')

    expect(context.rows.map(&:name)).to eq(['Anna Real', 'Zoe Real'])
  end

  it 'counts connected members against the full roster' do
    student_context(user_lti_id: 'lti-1', user: create(:user))
    student_context(user_lti_id: 'lti-2')

    expect(context.connected_count).to eq(1)
    expect(context.total_count).to eq(2)
    expect(context.pending_count).to eq(1)
  end

  # Identity is Dashboard-side (same sources as the Students tab); the anonymized
  # LMS shares no names.
  it 'shows the enrollment real name + username for connected rows' do
    anna = create(:user, username: 'WikiAnna')
    enroll(anna, real_name: 'Anna Real')
    student_context(user_lti_id: 'lti-1', user: anna)

    expect(context.rows.map { |r| [r.name, r.username] })
      .to eq([['Anna Real', 'WikiAnna']])
  end

  it 'leaves the name blank (username still shown) for a connected row without one' do
    student_context(user_lti_id: 'lti-1', user: create(:user, username: 'WikiUser'))

    expect(context.rows.map { |r| [r.name, r.username] }).to eq([[nil, 'WikiUser']])
  end

  # The opaque id names nobody, and no instructor-reachable Canvas page
  # resolves it, so pending members are a count rather than a row.
  it 'keeps pending members out of the rows, counting them instead' do
    student_context(user_lti_id: 'lti-opaque-1')
    student_context(user_lti_id: 'lti-opaque-2')

    expect(context.rows).to be_empty
    expect(context.pending_count).to eq(2)
  end

  # Stored NRPS status, surfaced as a per-row flag: staff-visible reconciliation
  # state only, never automatic disenrollment.
  describe 'the removed-in-Canvas flag' do
    it 'flags a connected student Canvas has since removed' do
      student_context(user_lti_id: 'lti-1', user: create(:user), status: 'Deleted')
      expect(context.rows.map(&:removed_in_lms)).to eq([true])
    end

    it 'flags a connected student whose Canvas enrollment is suspended' do
      student_context(user_lti_id: 'lti-1', user: create(:user), status: 'Inactive')
      expect(context.rows.map(&:removed_in_lms)).to eq([true])
    end

    it 'does not flag an Active student' do
      student_context(user_lti_id: 'lti-1', user: create(:user), status: 'Active')
      expect(context.rows.map(&:removed_in_lms)).to eq([false])
    end

    # nil status means no NRPS response has covered the member yet (they linked
    # via their own launch); absence of data is not a removal.
    it 'does not flag a student the roster sync has not covered yet' do
      student_context(user_lti_id: 'lti-1', user: create(:user))
      expect(context.rows.map(&:removed_in_lms)).to eq([false])
    end
  end

  describe '#student_details_path' do
    it "points at the viewer's per-student details view on the bound course" do
      viewer = create(:user, username: 'Stu Dent')
      context = described_class.new(line_item:, instructor: false, user: viewer)
      expect(context.student_details_path)
        .to eq("/courses/#{course.slug}/students/articles/Stu_Dent")
    end

    it 'is nil without a viewer' do
      expect(described_class.new(line_item:, instructor: true).student_details_path).to be_nil
    end
  end

  it 'excludes instructor and staff memberships' do
    LtiContext.create!(lti_course_binding: binding, user_lti_id: 'lti-inst',
                       lms_id: 'platform-x', roles: ['vocab/membership#Instructor'],
                       user: create(:user, username: 'WikiTeacher'))
    anna = create(:user, username: 'WikiAnna')
    enroll(anna, real_name: 'Anna Real')
    student_context(user_lti_id: 'lti-1', user: anna)

    expect(context.rows.map(&:name)).to eq(['Anna Real'])
    expect(context.total_count).to eq(1)
  end
end
