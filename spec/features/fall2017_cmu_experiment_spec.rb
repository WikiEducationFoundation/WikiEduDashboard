# frozen_string_literal: true

require 'rails_helper'

describe 'email links for Fall 2017 CMU experiment', type: :feature do
  let(:admin) { create(:admin) }
  let(:email_code) { 'abcdefgabcdefg' }
  let(:course) do
    create(:course, flags: { fall_2017_cmu_experiment: 'email_sent',
                             fall_2017_cmu_experiment_email_code: email_code })
  end
  let(:campaign) { create(:campaign, slug: 'fall_2017') }

  describe '#opt_in' do
    it 'updates the course experiment status' do
      visit "/experiments/fall2017_cmu_experiment/#{course.id}/#{email_code}/opt_in"
      expect(course.reload.flags[Fall2017CmuExperiment::STATUS_KEY]).to eq('opted_in')
    end

    it 'errors if email_code is wrong' do
      expect do
        visit "/experiments/fall2017_cmu_experiment/#{course.id}/wrongcode/opt_in"
      end.to raise_error Experiments::IncorrectEmailCodeError
    end
  end

  describe '#opt_out' do
    it 'updates the course experiment status' do
      visit "/experiments/fall2017_cmu_experiment/#{course.id}/#{email_code}/opt_out"
      expect(course.reload.flags[Fall2017CmuExperiment::STATUS_KEY]).to eq('opted_out')
    end

    it 'errors if email_code is wrong' do
      expect do
        visit "/experiments/fall2017_cmu_experiment/#{course.id}/wrongcode/opt_out"
      end.to raise_error Experiments::IncorrectEmailCodeError
    end
  end

  describe '#course_list' do
    before { course.campaigns << campaign }

    it 'sends a csv of all fall 2017 courses with their experiment status' do
      login_as(admin)
      visit '/experiments/fall2017_cmu_experiment/course_list'
      expect(page.body).to have_content('email_sent')
    end
  end
end
