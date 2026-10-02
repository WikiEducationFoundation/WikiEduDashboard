# frozen_string_literal: true

require 'rails_helper'

describe LtiScoreSignature, type: :model do
  let(:course) { create(:course) }
  let(:user) { create(:user) }
  let(:binding) do
    LtiCourseBinding.create!(
      course: course, lms_id: 'p-x', lms_family: 'canvas',
      lms_context_id: 'c-1', lms_resource_link_id: 'rl-1'
    )
  end
  let(:context) do
    LtiContext.create!(
      lti_course_binding: binding, user: user, user_lti_id: 'lti-u', lms_id: 'p-x'
    )
  end
  let(:line_item) do
    LtiLineItem.create!(
      lti_course_binding: binding, gradable_type: 'TrainingProgress',
      lineitem_id: 'https://lms.example.com/li/x'
    )
  end

  it 'validates signature and last_pushed_at presence (FK presence enforced by DB null: false)' do
    bad = described_class.new
    expect(bad).not_to be_valid
    expect(bad.errors[:signature]).to be_present
    expect(bad.errors[:last_pushed_at]).to be_present
  end

  it 'enforces a unique (line_item, context) pair' do
    described_class.create!(
      lti_line_item: line_item, lti_context: context,
      signature: 'a', last_pushed_at: Time.current
    )
    dup = described_class.new(
      lti_line_item: line_item, lti_context: context,
      signature: 'b', last_pushed_at: Time.current
    )
    expect(dup).not_to be_valid
    expect(dup.errors[:lti_context_id]).to be_present
  end
end
