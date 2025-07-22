# frozen_string_literal: true

require 'rails_helper'

describe AlertMailer do
  let(:user) { create(:user, email: 'user@wikiedu.org') }
  let(:article) { create(:article, title: 'Almost_deleted') }
  let(:course) { create(:course) }
  let(:admin) { create(:admin, email: 'admin@wikiedu.org') }

  describe '.send_alert_email' do
    let(:mail) { described_class.send_alert_email(alert, user) }
    let(:admin_mail) { described_class.send_alert_email(alert, admin) }

    context 'for an ArticlesForDeletionAlert' do
      let(:alert) do
        create(:alert, type: 'ArticlesForDeletionAlert',
                       article:, user:, course:)
        Alert.last
      end

      it 'delivers an email with relevant details to the recipient' do
        expect(Features).to receive(:email?).and_return(true)
        expect(mail.subject).to match(article.title)
        expect(mail.to).to eq([user.email])
      end

      it 'includes resolve link if the recipient is admin' do
        expect(Features).to receive(:email?).and_return(true)
        expect(admin_mail.to).to eq([admin.email])
        expect(admin_mail.body.encoded).to include('Resolve')
      end
    end
  end
end
