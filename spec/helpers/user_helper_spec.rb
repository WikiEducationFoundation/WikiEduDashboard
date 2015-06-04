require 'rails_helper'

describe UsersHelper, type: :helper do
  describe '.user_links' do
    it 'should return contrib links for multiples users' do
      build(:user).save
      build(:trained).save
      links = user_links(User.all)
      expect(links).to include('<a href=')
    end
  end

  describe '.contribution_link' do
    it 'should return a link to a user\'s contributions page' do
      user = build(:user)
      link = contribution_link(user)
      expect(link).to include('<a href=')
    end
  end
end
