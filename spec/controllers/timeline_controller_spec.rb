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

    describe 'modifying blocks' do
      it 'updates the block content and title' do
        title = 'My New Title'
        content = 'My New Content'
        weeks = [{
          id: week.id,
          blocks: [{
            id: block.id,
            title: title,
            content: content
          }]
        }]

        params = post_params.merge(weeks: weeks)
        post "/courses/#{course.slug}/timeline", params: params, headers: headers, as: :json

        block.reload
        expect(block.title).to eq(title)
        expect(block.content).to eq(content)
      end

      it 'does not update the block content or title if not allowed' do
        uneditable_block = create(:block,
                                  is_editable: false,
                                  week_id: week.id,
                                  training_module_ids: first_ids)

        title = 'My New Title'
        content = 'My New Content'
        weeks = [{
          id: week.id,
          blocks: [{
            id: uneditable_block.id,
            title: title,
            content: content
          }]
        }]
        params = post_params.merge(weeks: weeks)
        post "/courses/#{course.slug}/timeline", params: params, headers: headers, as: :json

        uneditable_block.reload
        expect(uneditable_block.title).not_to eq(title)
        expect(uneditable_block.content).not_to eq(content)
      end

      it 'can still edit other fields if block.is_uneditable is false' do
        uneditable_block = create(:block,
                                  is_editable: false,
                                  week_id: week.id,
                                  training_module_ids: first_ids)

        order = 3
        weeks = [{
          id: week.id,
          blocks: [{
            id: uneditable_block.id,
            order: order
          }]
        }]
        params = post_params.merge(weeks: weeks)
        post "/courses/#{course.slug}/timeline", params: params, headers: headers, as: :json
        expect(uneditable_block.reload.order).to eq(order)
      end
    end

    describe 'setting training_module_ids' do
      it 'sets the training_module_ids to value provided' do
        # FIXME: Remove workaround after Rails 5.0.1
        # See https://github.com/rails/rails/issues/26075
        headers = { 'HTTP_ACCEPT' => 'application/json' }
        post "/courses/#{course.slug}/timeline", params: post_params, headers: headers, as: :json
        expect(block.reload.training_module_ids).to eq(ids)
      end
      it 'does not set the training_module_ids if not allowed' do
        uneditable_block = create(:block,
                                  is_editable: false,
                                  week_id: week.id,
                                  training_module_ids: first_ids)

        training_module_ids = [1, 2, 3]
        weeks = [{
          id: week.id,
          blocks: [{
            id: uneditable_block.id,
            training_module_ids: training_module_ids
          }]
        }]
        params = post_params.merge(weeks: weeks)
        headers = { 'HTTP_ACCEPT' => 'application/json' }

        post "/courses/#{course.slug}/timeline", params: params, headers: headers, as: :json
        expect(uneditable_block.reload.training_module_ids).not_to eq(training_module_ids)
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
