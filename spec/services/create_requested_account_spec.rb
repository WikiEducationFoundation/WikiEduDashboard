# frozen_string_literal: true

require 'rails_helper'

describe CreateRequestedAccount, focus: true do
  let(:creator) { create(:admin) }
  let(:course) { create(:course) }
  let(:user) { create(:user) }
  let(:requested_account) { create(:requested_account, course_id: course.id, username: user.username, email: user.email) }
  let(:subject) do
    described_class.new(requested_account, creator)
  end

  it 'creates the requested accounts' do
    stub_account_creation
    expect(subject.result[:failure]).to_not be_nil
  end
end
