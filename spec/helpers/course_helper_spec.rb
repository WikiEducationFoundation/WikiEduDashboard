require 'rails_helper'

describe CourseHelper, type: :helper do
  describe '.user_links' do
    it 'should return contrib links for multiples users' do
      build(:user).save
      build(:trained).save
      links = user_links(User.all)
      expect(links).to include('<a href=')
    end
  end
end
