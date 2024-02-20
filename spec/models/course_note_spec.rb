# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CourseNote, type: :model do
  let(:course) { create(:course) }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:courses_id) }
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:text) }
    it { is_expected.to validate_presence_of(:edited_by) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:course) }
  end

  describe '#create_new_note' do
    it 'creates a new course note with valid attributes' do
      attributes = { courses_id: course.id, title: 'Note Title', text: 'Note Text', edited_by: 'User' }
      course_note = described_class.new
      expect(course_note.create_new_note(attributes)).to be_truthy
      expect(course_note).to be_persisted
    end

    it 'fails to create a new course note with invalid attributes' do
      attributes = { courses_id: course.id, title: nil, text: 'Note Text', edited_by: 'User' }
      course_note = described_class.new
      expect(course_note.create_new_note(attributes)).to be_falsey
      expect(course_note).not_to be_persisted
    end
  end

  describe '#update_note' do
    let(:course_note) { create(:course_note, courses_id: course.id) }

    it 'updates the course note with valid attributes' do
      attributes = { title: 'Updated Title', text: 'Updated Text', edited_by: 'Updated User' }
      expect(course_note.update_note(attributes)).to be_truthy
      expect(course_note.reload.title).to eq('Updated Title')
      expect(course_note.reload.text).to eq('Updated Text')
      expect(course_note.reload.edited_by).to eq('Updated User')
    end
  end
end
