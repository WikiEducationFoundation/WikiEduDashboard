# frozen_string_literal: true

require 'rails_helper'

# Signing out changes state, so it takes a DELETE: a GET could come from any
# page's <img> or link and sign the user out without their asking.
describe 'Signing out', type: :request do
  let(:user) { create(:user, wiki_token: 'token', wiki_secret: 'secret') }

  before { login_as user }

  it 'signs the user out and clears their wiki credentials on DELETE' do
    delete '/sign_out'
    expect(response).to redirect_to(root_path)
    expect(user.reload.wiki_token).to be_nil
    get '/'
    expect(response.body).to match(/data-usersignedin=.false./)
  end

  it 'leaves the user signed in on GET' do
    get '/sign_out'
    expect(response).to redirect_to(root_path)
    expect(user.reload.wiki_token).to eq('token')
    get '/'
    expect(response.body).to match(/data-usersignedin=.true./)
  end
end
