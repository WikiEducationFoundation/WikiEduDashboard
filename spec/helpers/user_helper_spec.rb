require 'rails_helper'

describe UserHelper, type: :helper do
  describe '.contribution_link' do
    it 'should return a link to a user\'s contributions page' do
      user = build(:user)
      link = contribution_link(user)
      expect(link).to include('<a href=')
    end
  end
end
