# frozen_string_literal: true

require 'rails_helper'

describe UsersHelper, type: :helper do
  describe '.contribution_link' do
    let(:user) { create(:user) }
    let(:course) { create(:course) }
    let(:courses_user) { create(:courses_user, course_id: course.id, user_id: user.id) }
    it 'should return a link to a user\'s contributions page' do
      link = contribution_link(courses_user)
      expect(link).to match(/<a.*href=/)
    end
  end
end
