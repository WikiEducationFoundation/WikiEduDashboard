# frozen_string_literal: true

require 'rails_helper'

describe SetupAssignmentViewContext do
  let(:binding) do
    LtiCourseBinding.create!(
      lms_id: 'platform-x', lms_family: 'canvas',
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

  it 'lists not-yet-connected members first, then connected, each by name' do
    student_context(user_lti_id: 'lti-1', name: 'Zoe', user: create(:user, username: 'Zoe'))
    student_context(user_lti_id: 'lti-2', name: 'Anna', user: create(:user, username: 'Anna'))
    student_context(user_lti_id: 'lti-3', name: 'Yann')
    student_context(user_lti_id: 'lti-4', name: 'Ben')

    expect(context.rows.map(&:name)).to eq(%w[Ben Yann Anna Zoe])
    expect(context.rows.map(&:connected?)).to eq([false, false, true, true])
  end

  it 'counts connected members against the full roster' do
    student_context(user_lti_id: 'lti-1', name: 'Anna', user: create(:user))
    student_context(user_lti_id: 'lti-2', name: 'Ben')

    expect(context.connected_count).to eq(1)
    expect(context.total_count).to eq(2)
  end

  it 'falls back to Wikipedia username, then opaque LMS id, when there is no LMS name' do
    student_context(user_lti_id: 'lti-linked', user: create(:user, username: 'WikiUser'))
    student_context(user_lti_id: 'lti-opaque-1')

    expect(context.rows.map(&:name)).to eq(%w[lti-opaque-1 WikiUser])
  end

  it 'excludes instructor and staff memberships' do
    LtiContext.create!(lti_course_binding: binding, user_lti_id: 'lti-inst',
                       lms_id: 'platform-x', name: 'Prof',
                       roles: ['vocab/membership#Instructor'])
    student_context(user_lti_id: 'lti-1', name: 'Anna')

    expect(context.rows.map(&:name)).to eq(['Anna'])
  end
end
