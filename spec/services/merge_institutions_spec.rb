# frozen_string_literal: true

require 'rails_helper'

describe MergeInstitutions do
  let(:survivor) { create(:institution, name: 'University of Washington, Bothell') }
  let(:duplicate) { create(:institution, name: 'UW Bothell') }
  let!(:course) { create(:course, institution: duplicate) }

  it 'moves the courses to the survivor and deletes the duplicate' do
    described_class.new(survivor:, duplicate:).merge
    expect(course.reload.institution).to eq(survivor)
    expect(Institution.exists?(duplicate.id)).to be false
  end

  it 'keeps the school name on the course untouched' do
    original_school = course.school
    described_class.new(survivor:, duplicate:).merge
    expect(course.reload.school).to eq(original_school)
  end

  it 'moves nothing if the delete fails' do
    allow(duplicate).to receive(:destroy!).and_raise(ActiveRecord::RecordNotDestroyed)
    expect { described_class.new(survivor:, duplicate:).merge }
      .to raise_error(ActiveRecord::RecordNotDestroyed)
    expect(course.reload.institution).to eq(duplicate)
  end
end
