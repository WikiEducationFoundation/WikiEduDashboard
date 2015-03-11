require 'rails_helper'

describe User do
  describe 'user creation' do
    it 'should create User objects' do
      ragesock = build(:user)
      ragesoss = build(:trained)
      expect(ragesock.wiki_id).to eq('Ragesock')
      # rubocop:disable Metrics/LineLength
      expect(ragesoss.contribution_url).to eq("https://#{Figaro.env.wiki_language}.wikipedia.org/wiki/Special:Contributions/Ragesoss")
      # rubocop:enable Metrics/LineLength
    end
  end

  describe 'training update' do
    it 'should update which users have completed training' do
      # Create a new user, who by default is assumed not to have been trained.
      build(:user).save
      ragesoss = User.all.first
      expect(ragesoss.trained).to eq(false)

      # Update trained users to see that user has really been trained
      User.update_trained_users
      ragesoss = User.all.first
      expect(ragesoss.trained).to eq(true)
    end
  end
end
