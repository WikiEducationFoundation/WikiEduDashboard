# frozen_string_literal: true

require 'rails_helper'

describe TimelineController, type: :request do
  describe '#update_timeline' do
    let(:admin)       { create(:admin) }
    let(:slug_params) { 'Wikipedia_Fellows/Basket-weaving_fellows_(summer_2018)' }
    let(:course)      { create(:course, slug: slug_params) }
    let(:week)        { create(:week) }
    let(:block)       { create(:block, week_id: week.id, training_module_ids: first_ids) }
    let(:first_ids)   { [1] }
    let(:ids)         { [1] }
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

    before do
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin)
    end

    describe 'setting training_module_ids' do
      it 'sets the training_module_ids to value provided' do
        # FIXME: Remove workaround after Rails 5.0.1
        # See https://github.com/rails/rails/issues/26075
        headers = { 'HTTP_ACCEPT' => 'application/json' }
        post "/courses/#{course.slug}/timeline", params: post_params, headers: headers, as: :json
        expect(block.reload.training_module_ids).to eq(ids)
      end

      context 'sending nil as training_module_ids param' do
        # When this gets set to [], ActiveRecord doesn't convert it to nil
        # like it does irl, so…
        let(:ids) { nil }

        it 'sets training_module_ids to [] as expected' do
          # FIXME: Remove workaround after Rails 5.0.1
          # See https://github.com/rails/rails/issues/26075
          post "/courses/#{course.slug}/timeline", params: post_params
          expect(block.reload.training_module_ids).to eq([])
        end
      end
    end
  end
end
