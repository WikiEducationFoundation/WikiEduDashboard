# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/wiki_userpage_output"

describe WikiUserpageOutput do
  let(:enrollment_template) { described_class.new(course).enrollment_template }
  let(:enrollment_summary) { described_class.new(course).enrollment_summary }

  context 'for a ClassroomProgramCourse' do
    let(:course) { create(:course, submitted: true) }

    it '#enrollment_template returns output without the type param' do
      expect(enrollment_template).not_to include('| type =')
    end

    it '#enrollment_summary includes wikilink' do
      expect(enrollment_summary).to match(/User has enrolled in \[\[.*\]\]/)
    end
  end

  context 'for a FellowsCohort' do
    let(:course) { create(:fellows_cohort) }

    it 'returns output with the type param' do
      expect(enrollment_template).to include('| type = scholars-and-scientists')
    end

    it '#enrollment_summary does not include wikilink' do
      expect(enrollment_summary).not_to match(/\[\[.*\]\]/)
    end
  end
end
