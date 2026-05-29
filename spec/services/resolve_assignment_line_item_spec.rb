# frozen_string_literal: true

require 'rails_helper'

describe ResolveAssignmentLineItem do
  let(:course) { create(:course) }
  let(:binding) do
    LtiCourseBinding.create!(course: course, lms_id: 'p', lms_family: 'canvas',
                             lms_context_id: 'c-1', lms_resource_link_id: 'rl-1')
  end
  let!(:line_item) do
    LtiLineItem.create!(lti_course_binding: binding, gradable_type: 'Block',
                        gradable_id: 1, lineitem_id: 'https://canvas/li/7', label: 'Evaluate')
  end

  def session(canvas_assignment_id:, ags_lineitem_url:)
    instance_double(LtiSession, canvas_assignment_id:, ags_lineitem_url:)
  end

  it 'finds by canvas_assignment_id when it has already been captured' do
    line_item.update!(canvas_assignment_id: 'ca-1')
    lti_session = session(canvas_assignment_id: 'ca-1', ags_lineitem_url: nil)
    expect(described_class.new(binding:, lti_session:).result).to eq(line_item)
  end

  it 'falls back to the launch line-item URL and backfills canvas_assignment_id' do
    lti_session = session(canvas_assignment_id: 'ca-2', ags_lineitem_url: 'https://canvas/li/7')
    expect(described_class.new(binding:, lti_session:).result).to eq(line_item)
    expect(line_item.reload.canvas_assignment_id).to eq('ca-2')
  end

  it 'returns nil when neither the id nor the URL matches' do
    lti_session = session(canvas_assignment_id: nil, ags_lineitem_url: 'https://canvas/li/NOPE')
    expect(described_class.new(binding:, lti_session:).result).to be_nil
  end

  it 'ignores archived line items' do
    line_item.archive!
    lti_session = session(canvas_assignment_id: nil, ags_lineitem_url: 'https://canvas/li/7')
    expect(described_class.new(binding:, lti_session:).result).to be_nil
  end
end
