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
      ragesoss = build(:user)
      expect(ragesoss.trained).to eq(false)
      User.update_trained_users
      # FIXME: test should properly run update_trained_users and then report
      # that Ragesoss has in fact completed the training.
      # expect(ragesoss.trained).to eq(true)
    end
  end
end
