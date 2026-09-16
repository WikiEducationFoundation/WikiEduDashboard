# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/course_creation_manager"

describe CourseCreationManager do
  describe 'privacy mode' do
    let(:real_title) { 'Introduction to Biology' }
    let(:real_school) { 'State University' }
    let(:instructor) { create(:user) }
    let(:course_params) do
      ActionController::Parameters.new(
        title: real_title, school: real_school, term: 'Fall 2026',
        start: '2026-08-24', end: '2026-12-11', subject: 'Biology',
        expected_students: 20
      ).permit!
    end
    let(:manager) do
      described_class.new(course_params, { language: 'en', project: 'wikipedia' }, nil, nil,
                          nil, instructor, nil, confidential: confidential)
    end

    before { stub_wiki_validation }

    context 'when the confidential flag is not set' do
      let(:confidential) { false }

      it 'stores the real title and school, as before' do
        course = manager.create
        expect(course.title).to eq(real_title)
        expect(course.school).to eq(real_school)
        expect(course).not_to be_confidential
      end
    end

    context 'when the confidential flag is set' do
      let(:confidential) { true }

      it 'stores obfuscated values in place of the real title and school' do
        course = manager.create
        expect(course.title).not_to include('Biology')
        expect(course.school).not_to include('State University')
      end

      it 'builds a slug that contains neither the real title nor the real school' do
        course = manager.create
        expect(course.slug).not_to include('Biology')
        expect(course.slug).not_to include('State')
      end

      it 'keeps the term in the slug, since the term is not confidential' do
        expect(manager.create.slug).to include('Fall_2026')
      end

      it 'keeps the real values in the admin-only record' do
        detail = manager.create.confidential_course_detail
        expect(detail.real_title).to eq(real_title)
        expect(detail.real_school).to eq(real_school)
      end

      it 'marks the course as confidential' do
        expect(manager.create).to be_confidential
      end

      it 'leaves fields that are not confidential alone' do
        course = manager.create
        expect(course.term).to eq('Fall 2026')
        expect(course.subject).to eq('Biology')
      end

      it 'gives a second privacy-mode course a different slug' do
        first = manager.create
        second = described_class.new(course_params, { language: 'en', project: 'wikipedia' },
                                     nil, nil, nil, instructor, nil, confidential: true).create
        expect(second.slug).not_to eq(first.slug)
        expect(second).to be_persisted
      end

      it 'retries with a fresh sequence when another course takes the one it picked' do
        # Simulate losing the race: the first sequence is taken between the time
        # it is allocated and the time the course is saved.
        allow(ConfidentialCourseDetail).to receive(:next_sequence).and_return(1, 1, 2)
        manager # allocates sequence 1
        taken_slug = obfuscated_slug('Fall 2026')
        create(:course, slug: taken_slug, title: obfuscated_title,
                        school: obfuscated_school, term: 'Fall 2026')
        course = manager.create
        expect(course).to be_persisted
        expect(course.slug).not_to eq(taken_slug)
      end

      it 'retries when another course takes the sequence but not the slug' do
        # A privacy-mode course in another term already holds sequence 1. The
        # slugs differ, so the collision is on the sequence index itself.
        other = create(:course, slug: obfuscated_slug('Spring 2026'), title: obfuscated_title,
                                school: obfuscated_school, term: 'Spring 2026')
        create(:confidential_course_detail, course: other, sequence: 1)
        allow(ConfidentialCourseDetail).to receive(:next_sequence).and_return(1, 2)
        course = manager.create
        expect(course).to be_persisted
        expect(course.confidential_course_detail.sequence).to eq(2)
      end

      it 'does not persist a course without its detail record' do
        allow(ConfidentialCourseDetail).to receive(:create!)
          .and_raise(ActiveRecord::RecordInvalid)
        expect { manager.create }.to raise_error(ActiveRecord::RecordInvalid)
        expect(Course.where(term: 'Fall 2026')).to be_empty
      end
    end
  end
end
