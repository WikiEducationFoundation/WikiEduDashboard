# frozen_string_literal: true

require 'rails_helper'

describe CopyCourseFromProduction do
  let(:url_base) { 'https://dashboard.wikiedu.org/courses/' }
  let(:existent_prod_course_slug) do
    'University_of_South_Carolina/Invertebrate_Zoology_(Spring_2022)'
  end

  context 'with courses in production' do
    let(:subject) do
      described_class.new(url_base + existent_prod_course_slug)
    end

    it 'copies the course' do
      VCR.use_cassette('load_course') do
        subject
        expect(Course.exists?(slug: existent_prod_course_slug)).to eq(true)
      end
    end

    it 'copy course to dev env' do
      VCR.use_cassette('load_course') do
        result = described_class.new(url_base + existent_prod_course_slug)
        expect(result.course).not_to be_nil
        expect(result.course.instructors).not_to be_nil
        expect(result.course.students).not_to be_nil
        expect(result.course.assignments).not_to be_nil

        # testing examples
        expect(result.course.instructors.first.username).to eq('Joshua Stone')
        expect(result.course.students.length).to eq(31)
        expect(result.course.assignments.length) > 0
      end
    end
  end
end
