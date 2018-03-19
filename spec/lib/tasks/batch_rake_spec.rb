# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/data_cycle/constant_update"
require "#{Rails.root}/lib/data_cycle/schedule_course_updates"
require "#{Rails.root}/lib/data_cycle/daily_update"
require "#{Rails.root}/lib/data_cycle/survey_update"

# https://robots.thoughtbot.com/test-rake-tasks-like-a-boss

describe 'batch:update_constantly' do
  include_context 'rake'

  describe 'update_constantly' do
    it 'initializes a ConstantUpdate' do
      expect(ConstantUpdate).to receive(:new)
      subject.invoke
    end
  end

  describe 'schedule_course_updates' do
    it 'initializes a ShortUpdate' do
      expect(ScheduleCourseUpdates).to receive(:new)
      rake['batch:schedule_course_updates'].invoke
    end
  end

  describe 'update_daily' do
    it 'initializes a DailyUpdate' do
      expect(DailyUpdate).to receive(:new)
      rake['batch:update_daily'].invoke
    end
  end

  describe 'survey_update' do
    it 'initializes a SurveyUpdate' do
      expect(SurveyUpdate).to receive(:new)
      rake['batch:survey_update'].invoke
    end
  end

  describe 'pause' do
    it 'creates a pause file' do
      pause_file = 'tmp/batch_pause.pid'
      rake['batch:pause'].invoke
      expect(File.exist?(pause_file)).to eq(true)
      File.delete pause_file
    end
  end

  describe 'resume' do
    it 'deletes a pause file' do
      pause_file = 'tmp/batch_pause.pid'
      File.open(pause_file, 'w') { |f| f.puts 'ohai' }
      rake['batch:resume'].invoke
      expect(File.exist?(pause_file)).to eq(false)
    end
  end
end
