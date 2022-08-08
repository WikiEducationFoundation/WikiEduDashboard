# frozen_string_literal: true

require 'rails_helper'

describe AddUsers do
  let(:course) { create(:course) }
  let(:existing_user) { create(:user, username: 'Ragesoss') }
  let(:normalized_username) { 'John of Reading' }
  let(:nonnormalized_username) { 'ursos_clio_herodoto' }
  let(:nonexistent_username) { 'This Is Not a Real User' }
  let(:usernames_list) do
    [existing_user.username, normalized_username, nonnormalized_username, nonexistent_username]
  end

  before do
    course.campaigns << Campaign.first
  end

  let(:subject) do
    described_class.new(course:, usernames_list:)
  end

  it 'returns all submitted usernames, and normalizes the ones that exist' do
    VCR.use_cassette 'add_users' do
      result = subject.add_all_at_once
      expect(result.size).to eq(usernames_list.size)
      expect(result['Ursos clio herodoto']).to have_key('success')
      expect(result[nonnormalized_username]).to be_nil
      expect(result[nonexistent_username]).to have_key('failure')
    end
  end
end
