# frozen_string_literal: true

require 'rails_helper'

describe CreateRequestedAccount, focus: true do
  let(:creator) { create(:admin) }
  let(:course) { create(:course) }
  let(:user) { create(:user) }
  let(:requested_account) { create(:requested_account, course_id: course.id, username: user.username, email: "Pepe") }
  let(:subject) do
    described_class.new(requested_account, creator)
  end

  it 'creates the requested accounts' do
    stub_account_creation
    allow(UserImporter).to receive(:new_from_username).and_return(user)
    expect(subject.result[:success]).not_to be_nil
    expect(user.username).to eq("Ragesock")
  end
end
