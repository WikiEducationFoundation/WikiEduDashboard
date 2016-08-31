# frozen_string_literal: true
require 'rails_helper'

describe RevisionFeedbackController do
  describe '#index' do
    let(:params) { { rev_id: 123456 } }
    let(:revision) { build(:revision, mw_rev_id: 123456) }

    context 'when the revision is in the database' do
      before do
        revision.save
        get :index, params
      end

      it 'renders without error' do
        expect(response.status).to eq(200)
      end
    end

    context 'when the revision is not in the database' do
      it 'imports and saves the revisions' do
        expect(Revision.count).to eq(0)
        expect(Revision).to receive(:new).and_return(revision)
        expect_any_instance_of(RevisionScoreImporter).to receive(:update_revision_scores)
        get :index, params
        expect(response.status).to eq(200)
        expect(Revision.count).to eq(1)
      end
    end
  end
end
