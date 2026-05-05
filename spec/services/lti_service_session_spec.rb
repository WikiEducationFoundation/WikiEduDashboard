# frozen_string_literal: true

require 'rails_helper'

describe LtiServiceSession do
  let(:binding) do
    LtiCourseBinding.create!(
      lms_id: 'platform-x',
      lms_family: 'canvas',
      lms_context_id: 'canvas-course-77',
      lms_resource_link_id: 'rl-99',
      ltiaas_service_credentials: 'svc-token'
    )
  end

  subject(:service) { described_class.new(binding) }

  describe 'NRPS / AGS verbs (skeleton, real impl in PRs 3-5)' do
    it 'raises NotImplementedError for fetch_memberships' do
      expect { service.fetch_memberships }
        .to raise_error(NotImplementedError, /PR 3/)
    end

    it 'raises NotImplementedError for upsert_line_item' do
      expect { service.upsert_line_item(label: 'x') }
        .to raise_error(NotImplementedError, /PR 4/)
    end

    it 'raises NotImplementedError for update_line_item' do
      expect { service.update_line_item('id', {}) }
        .to raise_error(NotImplementedError, /PR 4/)
    end

    it 'raises NotImplementedError for delete_line_item' do
      expect { service.delete_line_item('id') }
        .to raise_error(NotImplementedError, /PR 4/)
    end

    it 'raises NotImplementedError for list_line_items' do
      expect { service.list_line_items }
        .to raise_error(NotImplementedError, /PR 4/)
    end

    it 'raises NotImplementedError for post_score' do
      expect do
        service.post_score(
          lineitem_id: 'id',
          user_lti_id: 'u',
          score_given: 1.0
        )
      end.to raise_error(NotImplementedError, /PR 5/)
    end
  end

  describe 'binding accessor' do
    it 'exposes the binding it was constructed with' do
      expect(service.binding).to eq(binding)
    end
  end
end
