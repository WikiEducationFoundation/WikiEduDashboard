# frozen_string_literal: true

require 'rails_helper'

describe TimelineController do
  describe '#update_timeline' do
    let(:admin)     { create(:admin) }
    let(:course)    { create(:course) }
    let(:week)      { create(:week) }
    let(:block)     { create(:block, week_id: week.id, training_module_ids: first_ids) }
    let(:first_ids) { [1] }
    let(:ids)       { [1] }
    let(:prams) do
      {
      }
    end
    let(:post_params) do
      {
        course_id: course.slug,
        format: :json,
        weeks: [{
          id: week.id,
          blocks: [{
            id: block.id,
            training_module_ids: ids
          }]
        }]
      }
    end
    before { allow(controller).to receive(:current_user).and_return(admin) }
    describe 'setting training_module_ids' do
      it 'sets the training_module_ids to value provided' do
        # FIXME: Remove workaround after Rails 5.0.1
        # See https://github.com/rails/rails/issues/26075
        request.content_type = 'application/json'
        post :update_timeline, params: post_params
        expect(block.reload.training_module_ids).to eq(ids)
      end
      context 'sending nil as training_module_ids param' do
        # When this gets set to [], ActiveRecord doesn't convert it to nil
        # like it does irl, so…
        let(:ids) { nil }
        it 'sets training_module_ids to [] as expected' do
          # FIXME: Remove workaround after Rails 5.0.1
          # See https://github.com/rails/rails/issues/26075
          request.content_type = 'application/json'
          post :update_timeline, params: post_params
          expect(block.reload.training_module_ids).to eq([])
        end
      end
    end
  end
end
