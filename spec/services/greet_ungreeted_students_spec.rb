# frozen_string_literal: true

require 'rails_helper'

describe GreetUngreetedStudents do
  let(:greeter) { create(:admin) }
  let(:student) { create(:user) }
  let(:course) { create(:course) }
  let(:subject) { described_class.new(course, greeter) }

  before do
    create(:courses_user, user: student, course:)
    stub_raw_action
    stub_contributors_query
    stub_oauth_edit
  end

  it 'posts enrollment templates and welcome message for an ungreeted student' do
    expect(student.greeted).to eq(false)
    # New section for the welcome message
    expect_any_instance_of(WikiEdits).to receive(:add_new_section).and_call_original
    # Templates are added to the top of user page, talk page, sandbox
    expect(AddSandboxTemplate).to receive(:new)
    expect_any_instance_of(WikiEdits).to receive(:add_to_page_top).twice.and_call_original
    subject
    expect(student.reload.greeted).to eq(true)
  end
end
