# frozen_string_literal: true

require 'rails_helper'

describe LtiContext do
  let(:binding) do
    LtiCourseBinding.create!(
      lms_id: 'platform-x',
      lms_family: 'canvas',
      lms_context_id: 'canvas-course-77',
      lms_resource_link_id: 'rl-99'
    )
  end
  let(:user) { create(:user) }

  describe 'validations and associations' do
    it 'requires user_lti_id and lms_id' do
      ctx = described_class.new
      expect(ctx).not_to be_valid
      expect(ctx.errors[:user_lti_id]).to be_present
      expect(ctx.errors[:lms_id]).to be_present
    end

    it 'permits nil user_id (NRPS-discovered, awaiting OAuth)' do
      ctx = described_class.new(user_lti_id: 'u', lms_id: 'platform-x',
                                lti_course_binding: binding)
      expect(ctx).to be_valid
    end
  end

  describe 'roles serialization' do
    it 'persists and reads back an array' do
      ctx = described_class.create!(
        user_lti_id: 'u',
        lms_id: 'platform-x',
        lti_course_binding: binding,
        roles: %w[role1 role2]
      )
      expect(described_class.find(ctx.id).roles).to eq(%w[role1 role2])
    end
  end

  describe 'linked / unlinked scopes' do
    let!(:linked) do
      described_class.create!(user: user, user_lti_id: 'u1',
                              lms_id: 'platform-x',
                              lti_course_binding: binding,
                              linked_at: Time.current)
    end
    let!(:unlinked) do
      described_class.create!(user_lti_id: 'u2', lms_id: 'platform-x',
                              lti_course_binding: binding)
    end

    it 'partitions correctly' do
      expect(described_class.linked).to include(linked)
      expect(described_class.linked).not_to include(unlinked)
      expect(described_class.unlinked).to include(unlinked)
      expect(described_class.unlinked).not_to include(linked)
      expect(linked).to be_linked
      expect(unlinked).not_to be_linked
    end
  end
end
