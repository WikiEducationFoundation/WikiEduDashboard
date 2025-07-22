# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Courses::SyllabusesController, type: :controller do
  describe '#update' do
    let(:course) { create(:course) }
    let(:instructor) do
      create(:user, id: 5)
      create(:courses_user, user_id: 5,
                            course_id: course.id,
                            role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
      User.find(5)
    end

    before do
      allow(controller).to receive(:current_user).and_return(instructor)
    end

    it 'saves a pdf' do
      file = fixture_file_upload('syllabus.pdf', 'application/pdf')
      post :update, params: { id: course.id, syllabus: file }
      expect(response.status).to eq(200)
      expect(course.syllabus).not_to be_nil
    end

    it 'deletes a saved file' do
      file = fixture_file_upload('syllabus.pdf', 'application/pdf')
      course.syllabus = file
      course.save
      expect(course.syllabus.exists?).to eq(true)
      post :update, params: { id: course.id, syllabus: 'null' }
      expect(course.syllabus.exists?).to eq(false)
    end

    it 'renders an error for disallowed file types' do
      file = fixture_file_upload('syllabus.torrent', 'application/x-bittorrent')
      post :update, params: { id: course.id, syllabus: file }
      expect(response.status).to eq(422)
    end
  end
end
