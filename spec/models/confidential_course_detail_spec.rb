# frozen_string_literal: true

require 'rails_helper'

describe ConfidentialCourseDetail do
  describe 'when its course is deleted' do
    let(:course) do
      create(:course, title: obfuscated_title, school: obfuscated_school, term: 'Fall 2026',
                      slug: obfuscated_slug('Fall 2026'))
    end

    before do
      create(:confidential_course_detail, course:, sequence: 1,
                                          real_title: 'Introduction to Biology',
                                          real_school: 'State University')
      course.destroy
    end

    it 'keeps the record, so the number is not handed out again' do
      expect(described_class.next_sequence).to eq(2)
    end

    it 'clears the real title and institution' do
      expect(described_class.find_by(sequence: 1))
        .to have_attributes(real_title: nil, real_school: nil)
    end
  end
end
