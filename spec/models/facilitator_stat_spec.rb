# frozen_string_literal: true

require 'rails_helper'

describe FacilitatorStat do
  let(:user1) { create(:user, username: 'Facilitator1') }
  let(:user2) { create(:user, username: 'Facilitator2') }

  let!(:stat_today_user1) do
    create(:facilitator_stat, user: user1,
                              snapshot_date: Time.zone.today,
                              total_programs_count: 5,
                              active_in_last_year: true)
  end

  let!(:stat_yesterday_user1) do
    create(:facilitator_stat, user: user1,
                              snapshot_date: 1.day.ago.to_date,
                              total_programs_count: 4,
                              active_in_last_year: true)
  end

  let!(:stat_today_user2) do
    create(:facilitator_stat, user: user2,
                              snapshot_date: Time.zone.today,
                              total_programs_count: 2,
                              active_in_last_year: false)
  end

  let!(:stat_old) do
    create(:facilitator_stat, user: user2,
                              snapshot_date: 3.months.ago.to_date,
                              total_programs_count: 1,
                              active_in_last_year: false)
  end

  describe 'validations' do
    it 'requires snapshot_date' do
      stat = build(:facilitator_stat, user: create(:user),
                                      snapshot_date: nil)
      expect(stat).not_to be_valid
      expect(stat.errors[:snapshot_date]).to be_present
    end

    it 'enforces uniqueness of user_id scoped to snapshot_date' do
      duplicate = build(:facilitator_stat, user: user1,
                                           snapshot_date: Time.zone.today)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to be_present
    end
  end

  describe '.latest' do
    it 'returns only records from the most recent snapshot date' do
      results = described_class.latest
      expect(results.pluck(:snapshot_date).uniq).to eq([Time.zone.today])
      expect(results).to include(stat_today_user1, stat_today_user2)
      expect(results).not_to include(stat_yesterday_user1, stat_old)
    end
  end

  describe '.current' do
    it 'returns latest records with users eager-loaded' do
      results = described_class.current
      expect(results).to include(stat_today_user1, stat_today_user2)
      # Verify eager loading by checking that no additional query is needed
      expect(results.first.association(:user)).to be_loaded
    end
  end

  describe '.for_user' do
    it 'returns all snapshots for a specific user ordered by date' do
      results = described_class.for_user(user1.id)
      expect(results).to eq([stat_yesterday_user1, stat_today_user1])
    end

    it 'returns empty relation for a user with no stats' do
      other_user = create(:user, username: 'NoStats')
      expect(described_class.for_user(other_user.id)).to be_empty
    end
  end

  describe '.for_date_range' do
    it 'returns records within the specified date range ordered by date' do
      start_date = 2.days.ago.to_date
      end_date = Time.zone.today
      results = described_class.for_date_range(start_date, end_date)
      expect(results).to include(stat_yesterday_user1,
                                 stat_today_user1,
                                 stat_today_user2)
      expect(results).not_to include(stat_old)
      expect(results).to eq(results.sort_by(&:snapshot_date))
    end
  end

  describe '.active_facilitators' do
    it 'returns only facilitators with active_in_last_year true' do
      results = described_class.active_facilitators
      expect(results).to include(stat_today_user1, stat_yesterday_user1)
      expect(results).not_to include(stat_today_user2, stat_old)
    end
  end
end
