# frozen_string_literal: true

require 'rails_helper'

describe PushCourseToSalesforce do
  let(:course) { create(:course, flags:, expected_students: 51, withdrawn:) }
  let(:content_expert) { create(:admin, username: 'abcdefg') }
  let(:subject) { described_class.new(course) }
  let(:salesforce_id) { 'a2qQ0101015h4HF' }
  let(:week) { create(:week, course:) }
  let(:withdrawn) { false }

  before do
    Setting.create(key: 'content_expert_salesforce_ids',
                   value: { content_expert.username => 'abcdefg' })
    JoinCourse.new(course:, user: content_expert,
                   role: CoursesUsers::Roles::WIKI_ED_STAFF_ROLE)
  end

  context 'when a course has a Salesforce record already' do
    let(:flags) { { salesforce_id: } }

    it 'updates the record' do
      expect_any_instance_of(Restforce::Data::Client).to receive(:update!).and_return(true)
      expect(subject.result).to eq(true)
    end

    it 'works for a VisitingScholarship' do
      expect_any_instance_of(Restforce::Data::Client).to receive(:update!).and_return(true)
      visiting_scholarship = create(:visiting_scholarship, flags:)
      subject = described_class.new(visiting_scholarship)
      expect(subject.result).to eq(true)
    end

    it 'works for a FellowsCohort' do
      expect_any_instance_of(Restforce::Data::Client).to receive(:update!).and_return(true)
      fellows_cohort = create(:fellows_cohort, flags:)
      subject = described_class.new(fellows_cohort)
      expect(subject.result).to eq(true)
    end

    it 'handles Salesforce API downtime gracefully' do
      expect_any_instance_of(Restforce::Data::Client).to receive(:update!)
        .and_raise(Faraday::ParsingError.new('Salesforce is down'))
      expect(subject.result).to be_nil
    end

    context 'when the course has sandbox and mainspace blocks' do
      before do
        # These are used for generate date for some optional fields.
        create(:block, week:, title: 'Start drafting your contributions')
        create(:block, week:, title: 'Begin moving your work to Wikipedia')
      end

      it 'sets the sandbox and mainspace assignment blocks' do
        expect_any_instance_of(Restforce::Data::Client).to receive(:update!).and_return(true)
        expect(subject.instance_variable_get(:@sandbox_block)).not_to be_nil
        expect(subject.instance_variable_get(:@mainspace_block)).not_to be_nil
      end
    end

    context 'when the course has wikidata stats' do
      let(:stats_hash) do
        { 'www.wikidata.org' =>
          { 'claims created' => 157,
            'claims changed' => 91,
            'claims removed' => 21,
            'items created' => 10,
            'references added' => 5 } }
      end

      before do
        create(:course_stats, course:, stats_hash:)
      end

      it 'includes key wikidata stats' do
        expect_any_instance_of(Restforce::Data::Client).to receive(:update!).and_return(true)
        fields = subject.send :course_salesforce_fields
        expect(fields[:Wikidata_items_created__c]).to eq(10)
        expect(fields[:Wikidata_claims_added_removed_or_edited__c]).to eq(157 + 91 + 21)
        expect(fields[:Wikidata_references_added__c]).to eq(5)
      end
    end

    context 'when the course is withdrawn' do
      let(:withdrawn) { true }

      it 'runs without error' do
        expect_any_instance_of(Restforce::Data::Client).to receive(:update!).and_return(true)
        expect(subject.result).to eq(true)
      end
    end

    context 'when the course lacks sandbox and mainspace blocks' do
      it 'the sandbox and mainspace assignment blocks are nil' do
        expect_any_instance_of(Restforce::Data::Client).to receive(:update!).and_return(true)
        expect(subject.instance_variable_get(:@sandbox_block)).to be_nil
        expect(subject.instance_variable_get(:@mainspace_block)).to be_nil
      end
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
