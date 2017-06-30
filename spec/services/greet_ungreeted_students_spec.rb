# frozen_string_literal: true

require 'rails_helper'

describe GreetUngreetedStudents do
  let(:greeter) { create(:admin) }
  let(:student) { create(:user) }
  let(:course) { create(:course) }
  let(:subject) { described_class.new(course, greeter) }
  before do
    create(:courses_user, user: student, course: course)
    stub_raw_action
    stub_contributors_query
    stub_oauth_edit
  end

  it 'posts a welcome message to the talk page of ungreeted students' do
    expect(student.greeted).to eq(false)
    expect_any_instance_of(WikiEdits).to receive(:add_new_section).and_call_original
    subject
    expect(student.reload.greeted).to eq(true)
  end
end
