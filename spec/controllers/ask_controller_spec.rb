require 'rails_helper'

describe AskController do
  before do
    allow(controller).to receive(:current_user).and_return(nil)
  end

  describe '#search' do
    it 'should redirect to ask.wikiedu.org' do
      query = { q: 'Help! I cannot enroll!' }
      expect(get 'search', query).to redirect_to(/.*ask\.wikiedu\.org.*/)
    end
  end
end
