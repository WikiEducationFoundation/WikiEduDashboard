require 'rails_helper'

describe 'Admin Authorization', type: :request do
  let(:admin) { create(:admin) }
  let(:user) { create(:user) }
  it 'grants access only for admin' do
    # Given admin is logged in
    sign_in admin
    
    # And he visits '/admin'
    get '/admin'
    
    # The he should be granted access
    expect(response.code).to eq("200")
  end

  it 'denies access to non admin users' do 
    # Given user is logged in
    sign_in user
    
    # And he visits '/admin'
    get '/admin'
    
    # The he should be rejected to root_path
    expect(response).to redirect_to(root_path)
  end
end
