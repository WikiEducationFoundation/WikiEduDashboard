require 'rails_helper'

describe ApplicationController do
  describe '#new_session_path' do
    it 'should return the sign in path' do
      result = controller.send(:new_session_path, nil)
      expect(result).to eq('/sign_in')
    end
  end
end
