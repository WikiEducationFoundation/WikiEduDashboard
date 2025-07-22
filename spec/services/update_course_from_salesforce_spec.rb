# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/app/services/update_course_from_salesforce"

describe UpdateCourseFromSalesforce do
  let(:course) { create(:course, flags:) }
  let(:salesforce_id) { 'a2qQ0101015h4HF' }
  let(:mock_salesforce_record) { { 'Course_Closed_Date__c' => '2018-06-07' } }
  let(:subject) { described_class.new(course) }

  context 'when a course has a Salesforce record' do
    let(:flags) { { salesforce_id: } }

    it 'updates the record with the closed date' do
      expect_any_instance_of(Restforce::Data::Client).to receive(:find)
        .and_return(mock_salesforce_record)
      subject
      expect(course.reload.flags[:closed_date]).to eq('2018-06-07')
    end

    it 'handles Salesforce API downtime gracefully' do
      expect_any_instance_of(Restforce::Data::Client).to receive(:find)
        .and_raise(Faraday::ParsingError.new('Salesforce is down'))
      subject
    end
  end

  context 'when a course does not have a Salesforce record' do
    let(:flags) { {} }

    it 'returns without error' do
      subject
      expect(course.reload.flags[:closed_date]).to be_nil
    end
  end
end
