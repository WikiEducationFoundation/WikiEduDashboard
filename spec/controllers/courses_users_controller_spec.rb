# frozen_string_literal: true

require 'rails_helper'

describe CoursesUsersController, type: :request do
  describe '#index' do
    let(:user) { create(:user) }
    let(:other_user) { create(:user, username: 'OtherUser') }
    let(:admin) { create(:admin) }
    let(:private_course) { create(:course, private: true, slug: 'Uni/Private_(term)') }
    let(:path) { '/courses_users.json' }

    before do
      create(:courses_user, course_id: private_course.id, user_id: user.id)
    end

    it 'lists the courses of the signed-in user' do
      login_as user
      get path, params: { user_id: user.id }
      expect(Oj.load(response.body)['courses'].pluck('id')).to eq([private_course.id])
    end

    it 'lets an admin list the courses of another user' do
      login_as admin
      get path, params: { user_id: user.id }
      expect(Oj.load(response.body)['courses'].pluck('id')).to eq([private_course.id])
    end

    it 'refuses a logged-out visitor' do
      get path, params: { user_id: user.id }
      expect(response.status).to eq(401)
    end

    it 'refuses a user asking for someone else\'s courses' do
      login_as other_user
      get path, params: { user_id: user.id }
      expect(response.status).to eq(401)
    end
  end
end
