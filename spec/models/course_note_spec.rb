# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CourseNote, type: :model do
  let(:course) { create(:course) }

  it 'is valid with valid attributes' do
    course_note = build(:course_note, course:)
    expect(course_note).to be_valid
  end

  it 'is invalid without a course' do
    course_note = build(:course_note, course: nil)
    expect(course_note).to be_invalid
    expect(course_note.errors[:courses_id]).to include("can't be blank")
  end

  it 'is invalid without a title' do
    course_note = build(:course_note, title: nil, course:)
    expect(course_note).to be_invalid
    expect(course_note.errors[:title]).to include("can't be blank")
  end

  it 'is invalid without text' do
    course_note = build(:course_note, text: nil, course:)
    expect(course_note).to be_invalid
    expect(course_note.errors[:text]).to include("can't be blank")
  end

  it 'is invalid without edited_by' do
    course_note = build(:course_note, edited_by: nil, course:)
    expect(course_note).to be_invalid
    expect(course_note.errors[:edited_by]).to include("can't be blank")
  end

  it 'updates note attributes successfully' do
    course_note = create(:course_note, course:)
    new_attributes = { title: 'Updated Title', text: 'Updated Text', edited_by: 'New Editor' }

    course_note.update_note(new_attributes)
    course_note.reload

    expect(course_note.title).to eq('Updated Title')
    expect(course_note.text).to eq('Updated Text')
    expect(course_note.edited_by).to eq('New Editor')
  end
end
