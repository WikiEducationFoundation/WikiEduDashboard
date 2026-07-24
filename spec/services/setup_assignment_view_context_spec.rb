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

  def student_context(user_lti_id:, name: nil, user: nil)
    LtiContext.create!(lti_course_binding: binding, user_lti_id:, name:, user:,
                       lms_id: 'platform-x', roles: ['vocab/membership#Learner'],
                       linked_at: user && Time.current)
  end

  def enroll(user, real_name:)
    CoursesUsers.create!(user:, course:, role: CoursesUsers::Roles::STUDENT_ROLE,
                         real_name:)
  end

  it 'lists not-yet-connected members first, then connected, each by name' do
    zoe = create(:user, username: 'WikiZoe')
    anna = create(:user, username: 'WikiAnna')
    enroll(zoe, real_name: 'Zoe Real')
    enroll(anna, real_name: 'Anna Real')
    student_context(user_lti_id: 'lti-1', user: zoe)
    student_context(user_lti_id: 'lti-2', user: anna)
    student_context(user_lti_id: 'lti-3', name: 'Yann')
    student_context(user_lti_id: 'lti-4', name: 'Ben')

    expect(context.rows.map(&:name)).to eq(['Ben', 'Yann', 'Anna Real', 'Zoe Real'])
    expect(context.rows.map(&:connected?)).to eq([false, false, true, true])
  end

  it 'counts connected members against the full roster' do
    student_context(user_lti_id: 'lti-1', name: 'Anna', user: create(:user))
    student_context(user_lti_id: 'lti-2', name: 'Ben')

    expect(context.connected_count).to eq(1)
    expect(context.total_count).to eq(2)
  end

  # Identity is Dashboard-side (same sources as the Students tab), designed
  # around anonymized mode where the LMS shares no names.
  it 'shows the enrollment real name + username for connected rows' do
    anna = create(:user, username: 'WikiAnna')
    enroll(anna, real_name: 'Anna Real')
    student_context(user_lti_id: 'lti-1', name: 'LMS-side Name', user: anna)

    expect(context.rows.map { |r| [r.name, r.username] })
      .to eq([['Anna Real', 'WikiAnna']])
  end

  it 'leaves the name blank (username still shown) for a connected row without one' do
    student_context(user_lti_id: 'lti-1', user: create(:user, username: 'WikiUser'))

    expect(context.rows.map { |r| [r.name, r.username] }).to eq([[nil, 'WikiUser']])
  end

  it 'labels pending rows with the LMS name, or the opaque id under anonymized mode' do
    student_context(user_lti_id: 'lti-named', name: 'Ben')
    student_context(user_lti_id: 'lti-opaque-1')

    expect(context.rows.map(&:name)).to contain_exactly('Ben', 'lti-opaque-1')
    expect(context.rows.map(&:username)).to eq([nil, nil])
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
                       lms_id: 'platform-x', name: 'Prof',
                       roles: ['vocab/membership#Instructor'])
    student_context(user_lti_id: 'lti-1', name: 'Anna')

    expect(context.rows.map(&:name)).to eq(['Anna'])
  end
end
