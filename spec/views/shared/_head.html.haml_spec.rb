require 'rails_helper'

describe 'shared/_head', type: :view do
  before do
    allow(view).to receive(:hot_javascript_tag).and_return('')
    allow(view).to receive(:i18n_javascript_tag).and_return('')
    allow(view).to receive(:logo_favicon_tag).and_return('')
    allow(view).to receive(:csrf_meta_tags).and_return('')
    allow(view).to receive(:content_for).and_return('')
    allow(view).to receive(:content_for?).and_return(false)
  end

  describe 'currentUser JS object' do
    context 'when username contains problematic characters' do
      UsernameTestHelper.test_usernames.each do |username|
        it "escapes the username #{username.inspect} and produces valid JS" do
          user = FactoryBot.build(:user, username: username)
          allow(view).to receive(:current_user).and_return(user)
          allow(view).to receive(:user_signed_in?).and_return(true)
          render
          expect(rendered).to include("username: #{username.to_json}")
        end
      end
    end

    context 'when there is no logged-in user' do
      before do
        allow(view).to receive(:current_user).and_return(nil)
        allow(view).to receive(:user_signed_in?).and_return(false)
        render
      end

      it 'renders an empty string for username without error' do
        expect(rendered).to include('username: ""')
      end
    end
  end
end
