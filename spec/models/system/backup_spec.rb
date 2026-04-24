# frozen_string_literal: true

# == Schema Information
#
# Table name: backups
#
#  id           :bigint           not null, primary key
#  scheduled_at :datetime
#  start        :datetime
#  end          :datetime
#  status       :string(255)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

require 'rails_helper'

describe Backup do
  describe '.current_backup' do
    it 'returns a fresh waiting backup' do
      backup = create(:backup, status: 'waiting')
      expect(described_class.current_backup).to eq(backup)
    end

    it 'returns a fresh running backup' do
      backup = create(:backup, status: 'running')
      expect(described_class.current_backup).to eq(backup)
    end

    it 'ignores a waiting backup older than FRESH_WINDOW' do
      create(:backup, status: 'waiting',
                      created_at: 3.hours.ago, updated_at: 3.hours.ago)
      expect(described_class.current_backup).to be_nil
    end

    it 'ignores a running backup older than FRESH_WINDOW' do
      create(:backup, status: 'running',
                      created_at: 3.hours.ago, updated_at: 3.hours.ago)
      expect(described_class.current_backup).to be_nil
    end

    it 'returns the fresh backup when a stale one is also present' do
      create(:backup, status: 'waiting',
                      created_at: 3.hours.ago, updated_at: 3.hours.ago)
      fresh = create(:backup, status: 'waiting')
      expect(described_class.current_backup).to eq(fresh)
    end

    it 'ignores terminal-status backups regardless of age' do
      create(:backup, status: 'finished')
      create(:backup, status: 'failed')
      expect(described_class.current_backup).to be_nil
    end

    it 'returns nil when there are no backup rows' do
      expect(described_class.current_backup).to be_nil
    end
  end
end
