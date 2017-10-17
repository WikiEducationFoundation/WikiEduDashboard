# frozen_string_literal: true

require 'rails_helper'

describe CheckWikiEmailWorker do
  let(:user) { create(:user) }

  context 'when the user is emailable' do
    before { allow_any_instance_of(CheckWikiEmail).to receive(:emailable?).and_return(true) }
    it 'does not send an email' do
      expect(WikiEmailMailer).not_to receive(:send_email_warning)
      CheckWikiEmailWorker.check(user: user)
    end
  end

  context 'when the user is not emailable' do
    before { allow_any_instance_of(CheckWikiEmail).to receive(:emailable?).and_return(false) }
    it 'sends an email' do
      allow(WikiEmailMailer).to receive(:send_email_warning)
      CheckWikiEmailWorker.check(user: user)
      expect(WikiEmailMailer).to have_received(:send_email_warning)
    end
  end
end
