# frozen_string_literal: true

require 'rails_helper'

describe CopyCourseFromProduction do
  let(:existent_prod_course) { 'https://dashboard.wikiedu.org/courses/University_of_California_Merced/Feminism,_Handmaids_and_Wild_Seeds_(Spring_2021)' }

  context 'with courses in production' do
    let(:subject) do
      described_class.new(existent_prod_course)
    end

    it 'copy course to dev env' do
      result = subject.result
      expect(result['failure']).to be_nil
      expect(result['success']).not_to be_nil
    end
  end
end
