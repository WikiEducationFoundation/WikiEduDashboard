# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join('lib/importers/user_importer')

describe UserImporter do
  describe 'OAuth model association' do
    it 'creates new user based on OAuth data' do
      VCR.use_cassette 'user/user_id' do
        info = OpenStruct.new(name: 'Ragesock')
        credentials = OpenStruct.new(token: 'foo', secret: 'bar')
        hash = OpenStruct.new(uid: '14093230',
                              info:,
                              credentials:)
        imported_user = described_class.from_omniauth(hash)
        expect(imported_user.username).to eq('Ragesock')
      end
    end

    it 'associates existing model with OAuth data' do
      existing = create(:user)
      info = OpenStruct.new(name: 'Ragesock')
      credentials = OpenStruct.new(token: 'foo', secret: 'bar')
      hash = OpenStruct.new(uid: '14093230',
                            info:,
                            credentials:)
      auth = described_class.from_omniauth(hash)
      expect(auth.id).to eq(existing.id)
    end

    it 'updates the username if it has changed' do
      existing = create(:user, id: 1, username: 'Old Username', global_id: 1234)
      info = OpenStruct.new(name: 'New Username')
      credentials = OpenStruct.new(token: 'foo', secret: 'bar')
      hash = OpenStruct.new(uid: '1234',
                            info:,
                            credentials:)
      auth = described_class.from_omniauth(hash)
      expect(auth.id).to eq(existing.id)
      expect(User.find(1).username).to eq('New Username')
    end
  end

  describe '.new_from_username' do
    it 'creates a new user' do
      VCR.use_cassette 'user/new_from_username' do
        username = 'Ragesoss'
        user = described_class.new_from_username(username)
        expect(user).to be_a(User)
        expect(user.username).to eq(username)
      end
    end

    it 'replaces underlines with whitespace in username' do
      VCR.use_cassette 'user/new_from_username' do
        username = 'Rob_(Wiki Ed)'
        user = described_class.new_from_username(username)
        expect(user).to be_a(User)
        expect(user.username).to eq('Rob (Wiki Ed)')
      end
    end

    it 'creates an new user who has no account on the default wiki' do
      VCR.use_cassette 'user/new_from_username_nondefault_wiki' do
        # This test assumes User:마티즈 has not been created on en.wiki:
        # https://en.wikipedia.org/wiki/Special:Log/%EB%A7%88%ED%8B%B0%EC%A6%88
        username = '마티즈'
        user = described_class.new_from_username(username)
        expect(user).to be_a(User)
        expect(user.username).to eq(username)
      end
    end

    it 'returns an existing user' do
      VCR.use_cassette 'user/new_from_username' do
        create(:user, id: 500, username: 'Ragesoss')
        username = 'Ragesoss'
        user = described_class.new_from_username(username)
        expect(user.id).to eq(500)
      end
    end

    it 'does not create a user if the username is not registered' do
      VCR.use_cassette 'user/new_from_username_nonexistent' do
        username = 'RagesossRagesossRagesoss'
        user = described_class.new_from_username(username)
        expect(user).to be_nil
      end
    end

    it 'works for users who have no Meta account if home wiki is provided' do
      VCR.use_cassette 'user/new_from_nonmeta_user' do
        username = 'Lukasoch'
        # This user has a wikipedia account for en and pl, but not a Meta one.
        user = described_class.new_from_username(username, MetaWiki.new)
        expect(user).to be_nil
        home_wiki = Wiki.new(language: 'pl', project: 'wikipedia')
        user = described_class.new_from_username(username, home_wiki)
        expect(user).not_to be_nil
      end
    end

    it 'does not create a user if input is only whitespace' do
      VCR.use_cassette 'user/new_from_username_nonexistent' do
        username = '    '
        user = described_class.new_from_username(username)
        expect(user).to be_nil
      end
    end

    it 'creates a user with the correct username capitalization' do
      VCR.use_cassette 'user/new_from_username' do
        # Basic lower case letter at the beginning, and whitespace
        username = ' zimmer1048 ' # First whitespace is a non-breaking space.
        user = described_class.new_from_username(username)
        expect(user.username).to eq('Zimmer1048')

        # Unicode lower case letter at the beginning
        username = 'áragetest'
        user = described_class.new_from_username(username)
        expect(user.username).to eq('Áragetest')
      end
    end

    it 'removes User: prefix from username' do
      VCR.use_cassette 'user/new_from_username_with_prefix' do
        username = 'User:Ragesock'
        user = described_class.new_from_username(username)
        expect(user.username).to eq('Ragesock')
      end
    end

    it 'removes invisible left-to-right and right-to-left marks from start or end of username' do
      VCR.use_cassette 'user/new_from_username_with_ltr' do
        username = 'Jashan1994' + 8206.chr + 8206.chr
        user = described_class.new_from_username(username)
        expect(user.username).to eq('Jashan1994')

        username = 8206.chr + 'Jashan1994'
        user = described_class.new_from_username(username)
        expect(user.username).to eq('Jashan1994')

        username = 8207.chr + 'Ofrit Assaf'
        user = described_class.new_from_username(username)
        expect(user.username).to eq('Ofrit Assaf')
      end
    end

    it 'updates the username of an existing user' do
      VCR.use_cassette 'user/new_from_renamed_user' do
        create(:user, id: 1, username: 'Old Username', global_id: '14093230')
        user = described_class.new_from_username('Ragesock')
        expect(user.username).to eq('Ragesock')
        expect(user.id).to eq(1)
        expect(user.global_id).to eq(14093230)
      end
    end
  end

  describe '.update_users' do
    it 'updates global ids and MetaWiki registration date' do
      create(:user, username: 'Ragesoss', global_id: nil)
      create(:user, username: 'Ragesock', global_id: nil)

      # Update trained users to see that user has really been trained
      VCR.use_cassette 'users/update_users' do
        described_class.update_users
      end
      ragesoss = User.find_by(username: 'Ragesoss')
      ragesock = User.find_by(username: 'Ragesock')
      # Since on-wiki trainings are not used anymore, we no longer update "trained"
      # status via UserImporter.
      # expect(ragesoss.trained).to eq(true)
      expect(ragesoss.global_id).to eq(827)
      expect(ragesock.global_id).to eq(14093230)
      expect(ragesoss.registered_at.to_date).to eq(Date.new(2006, 7, 14))
      expect(ragesock.registered_at.to_date).to eq(Date.new(2012, 7, 11))
    end
  end

  describe '.update_user_from_wiki' do
    let(:course) { create(:course) }

    it 'cleans up records when there are collisions' do
      VCR.use_cassette 'user/new_from_renamed_user' do
        original = create(:user, username: 'Ragesock', global_id: 14093230)
        dupe = create(:user, username: ' Ragesock')
        create(:courses_user, user: dupe, course:)

        expect(Sentry).to receive(:capture_exception).and_call_original
        described_class.update_user_from_wiki(dupe, MetaWiki.new)

        expect(original.courses_users.count).to eq(1)
      end
    end

    it 'sets the registration date from English Wikipedia' do
      VCR.use_cassette 'user/enwiki_only_account' do
        user = create(:user, username: 'Brady2421')
        enwiki = Wiki.get_or_create(language: 'en', project: 'wikipedia')
        described_class.update_user_from_wiki(user, enwiki)
        expect(user.registered_at).not_to be_nil
      end
    end
  end
end
