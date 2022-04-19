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
      subject
      expect(Course.exists?(slug: existent_prod_course_slug)).to eq(true)
    end

    it 'copy course to dev env' do
      result = subject.result
      expect(result['course']).not_to be_nil
    end

  end
end
