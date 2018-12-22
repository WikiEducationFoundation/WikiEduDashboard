# frozen_string_literal: true

require 'rails_helper'

describe GreetingController, type: :request do
  subject { put '/greeting', params: { course_id: course.id } }

  let(:admin) { create(:admin) }
  let(:course) { create(:course) }

  before do
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin)
  end

  it 'greets ungreeted students' do
    expect(GreetUngreetedStudents).to receive(:new).and_call_original
    subject
  end
end
