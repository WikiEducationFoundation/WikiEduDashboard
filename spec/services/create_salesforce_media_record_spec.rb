# frozen_string_literal: true

require 'rails_helper'

describe CreateSalesforceMediaRecord do
  let(:course) { create(:course, flags: { salesforce_id: 'a2qQ0101015h4HF' }) }
  let(:user) { create(:user) }
  let(:article) { create(:article) }
  let(:subject) do
    described_class.new(
      course: course,
      user: user,
      article: article,
      before_rev_id: 1234,
      after_rev_id: 3456
    )
  end

  it 'calls #create! on the Restforce client and returns a url' do
    expect_any_instance_of(Restforce::Data::Client).to receive(:create!)
      .and_return('a2qQQ101015h4GG')
    expect(subject.url).to include('a2qQQ101015h4GG')
  end
end
