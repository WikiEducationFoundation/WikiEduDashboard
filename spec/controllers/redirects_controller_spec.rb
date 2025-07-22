# frozen_string_literal: true

require 'rails_helper'

describe RedirectsController, type: :request do
  let(:user) { create(:user, username: 'ExampleUser') }

  describe '#sandbox' do
    it 'redirects to the sandbox of the current users' do
      login_as user
      get '/redirect/sandbox/my_sandbox?param=foo'
      expect(response.status).to redirect_to('https://en.wikipedia.org/wiki/User:ExampleUser/my_sandbox?param=foo')
    end
  end
end
