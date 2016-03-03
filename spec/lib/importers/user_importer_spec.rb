require 'rails_helper'
require "#{Rails.root}/lib/importers/user_importer"
require "#{Rails.root}/lib/legacy_courses/legacy_course_importer"

describe UserImporter do
  describe 'OAuth model association' do
    it 'should create new user based on OAuth data' do
      VCR.use_cassette 'user/user_id' do
        info = OpenStruct.new(name: 'Ragesock')
        credentials = OpenStruct.new(token: 'foo', secret: 'bar')
        hash = OpenStruct.new(uid: '14093230',
                              info: info,
                              credentials: credentials)
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
                            credentials: credentials)
      auth = UserImporter.from_omniauth(hash)
      expect(auth.id).to eq(existing.id)
    end
  end

  describe '.new_from_username' do
    it 'should create a new user' do
      VCR.use_cassette 'user/new_from_username' do
        username = 'Ragesoss'
        user = UserImporter.new_from_username(username)
        expect(user.id).to eq(319203)
      end
    end

    it 'should return an existing user' do
      VCR.use_cassette 'user/new_from_username' do
        create(:user, id: 319203, username: 'Ragesoss')
        username = 'Ragesoss'
        user = UserImporter.new_from_username(username)
        expect(user.id).to eq(319203)
      end
    end

    it 'should not create a user if the username is not registered' do
      VCR.use_cassette 'user/new_from_username_nonexistent' do
        username = 'RagesossRagesossRagesoss'
        user = UserImporter.new_from_username(username)
        expect(user).to be_nil
      end
    end
  end

  describe '.update_users' do
    it 'should update which users have completed training' do
      # Create a new user, who by default is assumed not to have been trained.
      ragesoss = create(:trained)
      expect(ragesoss.trained).to eq(false)

      # Update trained users to see that user has really been trained
      UserImporter.update_users
      ragesoss = User.all.first
      expect(ragesoss.trained).to eq(true)
    end

    it 'should handle exceptions for missing users' do
      user = [build(:user)]
      UserImporter.update_users(user)
    end
  end

  describe '.add_users' do
    it 'should add users based on course data' do
      VCR.use_cassette 'wiki/add_users' do
        course = create(:course,
                        id: 351)
        data = LegacyCourseImporter.get_course_info 351
        student_data = data[0]['participants']['student']
        UserImporter.add_users(student_data, 0, course)
        expect(course.students.all.count).to eq(12)
      end
    end
  end
end
