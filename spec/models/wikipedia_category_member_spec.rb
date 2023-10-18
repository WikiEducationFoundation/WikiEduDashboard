# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WikipediaCategoryMember, type: :model do
  describe '#fetch_category_members' do
    it 'fetches and saves category members' do
      response = instance_double('response', status: 200,
      data: { 'categorymembers' => [{ 'title' => 'Member 1' }, { 'title' => 'Member 2' }] })

      wiki_api = instance_double('wiki_api', query: response)
      allow(WikiApi).to receive(:new).and_return(wiki_api)

      described_class.create(category_member: 'Member 2')
      described_class.create(category_member: 'Member 3')

      subject.fetch_category_members

      expect(described_class.pluck(:category_member)).to contain_exactly('Member 1', 'Member 2')

      expect(described_class.find_by(category_member: 'Member 3')).to be_nil
    end

    it 'logs a warning on API failure' do
      response = instance_double('response', status: 500)

      wiki_api = instance_double('wiki_api', query: response)
      allow(WikiApi).to receive(:new).and_return(wiki_api)

      expect(Rails.logger).to receive(:warn).with('Failed to fetch categorymembers data')

      subject.fetch_category_members
    end
  end
end
