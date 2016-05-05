require 'rails_helper'

describe AlertMailer do
  let(:user) { create(:user, email: 'user@wikiedu.org') }
  let(:article) { create(:article, title: 'Almost_deleted') }
  let(:alert) { create(:alert, article_id: article.id) }

  describe '.alert' do
    let(:mail) { described_class.alert(alert, user) }
    it 'delivers an email with to the content expert' do
      expect(Features).to receive(:email?).and_return(true)
      expect(mail.subject).to match(article.title)
      expect(mail.to).to eq([user.email])
    end
  end
end
