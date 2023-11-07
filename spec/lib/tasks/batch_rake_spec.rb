# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join('lib/data_cycle/constant_update')
require Rails.root.join('lib/data_cycle/schedule_course_updates')
require Rails.root.join('lib/data_cycle/daily_update')
require Rails.root.join('lib/data_cycle/survey_update')
require Rails.root.join('lib/tickets/ticket_notification_emails')

# https://robots.thoughtbot.com/test-rake-tasks-like-a-boss

describe 'batch:pause' do
  include_context 'rake'

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
