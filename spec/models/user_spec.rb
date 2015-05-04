require 'rails_helper'
require "#{Rails.root}/lib/importers/user_importer"

describe User do
  describe 'user creation' do
    it 'should create User objects' do
      ragesock = build(:user)
      ragesoss = build(:trained)
      ragesauce = build(:admin)
      expect(ragesock.wiki_id).to eq('Ragesock')
      # rubocop:disable Metrics/LineLength
      expect(ragesoss.contribution_url).to eq("https://#{Figaro.env.wiki_language}.wikipedia.org/wiki/Special:Contributions/Ragesoss")
      # rubocop:enable Metrics/LineLength
      expect(ragesauce.is_admin).to be true
    end

    it 'should cache User activity' do
      build(:user,
            id: 1,
            wiki_id: 'Ragesoss'
      ).save

      build(:course,
            id: 1,
            start: '2015-01-01'.to_date,
            end: '2015-07-01'.to_date,
            title: 'Underwater basket-weaving'
      ).save

      build(:article,
            id: 1,
            title: 'Selfie',
            namespace: 0,
            views: 1234
      ).save

      build(:revision,
            id: 1,
            user_id: 1,
            article_id: 1,
            date: '2015-01-01'.to_date,
            characters: 9000,
            views: 1234
      ).save

      build(:revision,
            id: 2,
            user_id: 1,
            article_id: 1,
            date: '2015-03-01'.to_date,
            characters: 3000,
            views: 567
      ).save

      # Assign the article to the user.
      build(:assignment,
            course_id: 1,
            user_id: 1,
            article_id: 1,
            article_title: 'Selfie'
      ).save

      # Make a course-user and save it.
      build(:courses_user,
            id: 1,
            course_id: 1,
            user_id: 1,
            assigned_article_title: 'Selfie'
      ).save

      # Make an article-course.
      build(:articles_course,
            id: 1,
            article_id: 1,
            course_id: 1
      ).save

      Article.update_all_caches
      User.update_all_caches

      user = User.all.first
      expect(user.view_sum).to eq(1234)
      expect(user.course_count).to eq(1)
      expect(user.revision_count).to eq(2)
      expect(user.revision_count('2015-02-01'.to_date)).to eq(1)
      expect(user.article_count).to eq(1)
    end
  end

  describe 'OAuth model association' do
    it 'should create new user based on OAuth data' do
      VCR.use_cassette 'user/user_id' do
        info = OpenStruct.new(name: 'Ragesock')
        credentials = OpenStruct.new(token: 'foo', secret: 'bar')
        hash = OpenStruct.new(uid: '14093230',
                              info: info,
                              credentials: credentials
        )
        auth = UserImporter.from_omniauth(hash)
        expect(auth.id).to eq(4_543_197)
      end
    end

    it 'should associate existing model with OAuth data' do
      existing = create(:user)
      info = OpenStruct.new(name: 'Ragesock')
      credentials = OpenStruct.new(token: 'foo', secret: 'bar')
      hash = OpenStruct.new(uid: '14093230',
                            info: info,
                            credentials: credentials
      )
      auth = UserImporter.from_omniauth(hash)
      expect(auth.id).to eq(existing.id)
    end
  end

  describe 'training update' do
    it 'should update which users have completed training' do
      # Create a new user, who by default is assumed not to have been trained.
      ragesoss = create(:trained)
      expect(ragesoss.trained).to eq(false)

      # Update trained users to see that user has really been trained
      UserImporter.update_users
      ragesoss = User.all.first
      expect(ragesoss.trained).to eq(true)
    end
  end
end
