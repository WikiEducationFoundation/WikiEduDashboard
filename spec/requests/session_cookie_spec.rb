# frozen_string_literal: true

require 'rails_helper'

# Cookies the app sets without their own SameSite attribute go out as
# SameSite=Lax, so cross-site POSTs and fetches arrive without the session.
describe 'Session cookie', type: :request do
  def cookie_header(name)
    Array(response.headers['Set-Cookie']).join("\n").split("\n")
                                         .find { |cookie| cookie.start_with?("#{name}=") }
  end

  it 'is SameSite=Lax' do
    login_as create(:user)
    get '/'
    expect(cookie_header('_wikiedudashboard_session')).to match(/samesite=lax/i)
  end
end
