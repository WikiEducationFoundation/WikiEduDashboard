# frozen_string_literal: true
require 'rails_helper'

describe PushCourseToSalesforce do
  let(:course) { create(:course, flags: flags) }
  let(:subject) { described_class.new(course) }
  let(:salesforce_id) { 'a2qQ0101015h4HF' }

  context 'when a course has a Salesforce record already' do
    let(:flags) { { salesforce_id: salesforce_id } }
    it 'updates the record' do
      expect_any_instance_of(Restforce::Data::Client).to receive(:update!).and_return(true)
      expect(subject.result).to eq(true)
    end

    it 'works for a VisitingScholarship' do
      expect_any_instance_of(Restforce::Data::Client).to receive(:update!).and_return(true)
      visiting_scholarship = create(:visiting_scholarship, flags: flags)
      subject = described_class.new(visiting_scholarship)
      expect(subject.result).to eq(true)
    end

    it 'handles Salesforce API downtime gracefully' do
      expect_any_instance_of(Restforce::Data::Client).to receive(:update!)
        .and_raise(Faraday::ParsingError.new('Salesforce is down'))
      expect(subject.result).to be_nil
    end
  end

  context 'when a course does not have a Salesforce record' do
    let(:flags) { {} }
    it 'creates the record and saves the ID as a course flag' do
      expect_any_instance_of(Restforce::Data::Client).to receive(:create!).and_return(salesforce_id)
      expect(subject.result).to eq(salesforce_id)
      expect(course.reload.flags[:salesforce_id]).to eq(salesforce_id)
    end
  end
end
