# frozen_string_literal: true

require 'rails_helper'

describe WikiEmailMailer do
  let(:user) { create(:user, email: 'newbie@example.edu') }

  describe '.send_email_warning' do
    let(:mail) { described_class.send_email_warning(user) }
    it 'delivers an email with a pointer to Wikipedia preferences' do
      allow(Features).to receive(:email?).and_return(true)
      expect(mail.body.encoded).to include('Open Wikipedia preferences')
      expect(mail.to).to eq([user.email])
    end
  end
end
