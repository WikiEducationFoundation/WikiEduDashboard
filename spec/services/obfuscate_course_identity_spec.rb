# frozen_string_literal: true

require 'rails_helper'

describe ObfuscateCourseIdentity do
  let(:params) do
    { title: 'Introduction to Biology', school: 'State University', term: 'Fall 2026' }
  end

  it 'replaces the title and school with obfuscated stand-ins' do
    identity = described_class.new(params)
    expect(identity.course_params[:title]).not_to include('Biology')
    expect(identity.course_params[:school]).not_to include('State University')
  end

  it 'leaves the term alone, since it is not confidential' do
    identity = described_class.new(params)
    expect(identity.course_params[:term]).to eq('Fall 2026')
  end

  it 'keeps the real values for the admin-only record' do
    identity = described_class.new(params)
    expect(identity.detail_attributes[:real_title]).to eq('Introduction to Biology')
    expect(identity.detail_attributes[:real_school]).to eq('State University')
  end

  it 'starts the sequence at 1 when no privacy-mode course exists yet' do
    expect(described_class.new(params).sequence).to eq(1)
  end

  it 'takes the next sequence after the highest one in use' do
    create(:confidential_course_detail, sequence: 41)
    expect(described_class.new(params).sequence).to eq(42)
  end

  it 'builds a distinct title per sequence, so the derived slug is unique' do
    first = described_class.new(params, sequence: 1).course_params[:title]
    second = described_class.new(params, sequence: 2).course_params[:title]
    expect(first).not_to eq(second)
  end

  it 'does not mutate the params it was given' do
    described_class.new(params)
    expect(params[:title]).to eq('Introduction to Biology')
  end
end
