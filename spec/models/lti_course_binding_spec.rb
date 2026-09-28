# frozen_string_literal: true

require 'rails_helper'

describe LtiCourseBinding do
  let(:base_attrs) do
    {
      lms_id: 'platform-x',
      lms_family: 'canvas',
      lms_context_id: 'canvas-course-77',
      lms_resource_link_id: 'rl-99'
    }
  end

  describe 'validations' do
    it 'requires the LMS identity tuple' do
      binding = described_class.new
      expect(binding).not_to be_valid
      expect(binding.errors[:lms_id]).to be_present
      expect(binding.errors[:lms_context_id]).to be_present
      expect(binding.errors[:lms_resource_link_id]).to be_present
    end

    it 'allows only one binding per linked course' do
      course = create(:course)
      described_class.create!(base_attrs.merge(course:))
      dup = described_class.new(base_attrs.merge(course:, lms_context_id: 'canvas-course-88'))
      expect(dup).not_to be_valid
      expect(dup.errors[:course_id]).to be_present
    end

    it 'allows many unbound bindings for different LMS courses' do
      described_class.create!(base_attrs)
      expect(described_class.new(base_attrs.merge(lms_context_id: 'canvas-course-88')))
        .to be_valid
    end

    # One row per LMS course, whichever resource link the launch came from.
    # Before this was enforced, two pre-link launches from different resource
    # links in one Canvas course minted two rows competing to be the bound one.
    it 'refuses a second row for the same LMS course' do
      described_class.create!(base_attrs)
      expect { described_class.create!(base_attrs.merge(lms_resource_link_id: 'rl-2')) }
        .to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe '.lookup' do
    it 'finds an existing binding by its LMS course identity' do
      binding = described_class.create!(base_attrs)
      expect(described_class.lookup(**base_attrs.slice(:lms_id, :lms_context_id)))
        .to eq(binding)
    end

    # A binding models an LMS course, so the resource link that created it is a
    # snapshot, not part of the key.
    it 'finds it regardless of which resource link the launch came from' do
      binding = described_class.create!(base_attrs.merge(lms_resource_link_id: 'rl-later'))
      expect(described_class.lookup(**base_attrs.slice(:lms_id, :lms_context_id)))
        .to eq(binding)
    end
  end

  # LTIAAS labels an LTI 1.1 launch "1.2.0", so legacy is "not 1.3". The
  # column defaults to 1.3 for rows that predate legacy support.
  describe '#legacy? and the lti_1_3 scope' do
    it 'defaults new rows to LTI 1.3' do
      binding = described_class.create!(base_attrs)
      expect(binding.lti_version).to eq('1.3.0')
      expect(binding).not_to be_legacy
    end

    it 'is legacy for any version other than 1.3' do
      expect(described_class.new(base_attrs.merge(lti_version: '1.2.0'))).to be_legacy
      expect(described_class.new(base_attrs.merge(lti_version: '1.1.0'))).to be_legacy
    end

    it 'scopes to the bindings with LTI services behind them' do
      current = described_class.create!(base_attrs)
      legacy = described_class.create!(base_attrs.merge(lms_context_id: 'canvas-course-88',
                                                        lti_version: '1.2.0'))
      expect(described_class.lti_1_3).to include(current)
      expect(described_class.lti_1_3).not_to include(legacy)
    end

    it 'requires a version' do
      expect(described_class.new(base_attrs.merge(lti_version: nil))).not_to be_valid
    end
  end

  describe '#claim_course' do
    let(:course) { create(:course) }
    let(:binding) { described_class.create!(base_attrs) }

    it 'adopts the claimed course when the binding has none' do
      binding.claim_course(course.id)
      expect(binding.course_id).to eq(course.id)
    end

    it 'keeps the course a binding already has' do
      other = create(:course, slug: 'School/Other_(2026)')
      binding.update!(course: other)
      binding.claim_course(course.id)
      expect(binding.course_id).to eq(other.id)
    end

    it 'skips a course already bound to another LMS course' do
      described_class.create!(base_attrs.merge(lms_context_id: 'elsewhere', course:))
      binding.claim_course(course.id)
      expect(binding.course_id).to be_nil
    end

    # The claim rides in a launch token that outlives the launch by 24 hours,
    # so it can name a course deleted since. Saving that id would fail the
    # foreign key and 500 inside the Canvas iframe.
    it 'skips a course that no longer exists' do
      deleted_id = course.id
      course.destroy
      binding.claim_course(deleted_id)
      expect(binding.course_id).to be_nil
    end
  end

  describe '#lms_display_name' do
    it 'returns the configured label for known LMS families' do
      binding = described_class.new(base_attrs.merge(lms_family: 'canvas'))
      expect(binding.lms_display_name).to eq('Canvas')
    end

    it 'titleizes the family code as a fallback for unknown LMSs' do
      binding = described_class.new(base_attrs.merge(lms_family: 'moodle'))
      expect(binding.lms_display_name).to eq('Moodle')
    end
  end

  describe 'optional course association' do
    it 'permits a nil course while waiting on instructor setup' do
      binding = described_class.create!(base_attrs)
      expect(binding.course).to be_nil
    end

    it 'destroys associated lti_contexts and lti_line_items on destroy' do
      binding = described_class.create!(base_attrs)
      LtiContext.create!(user_lti_id: 'u',
                         lms_id: 'platform-x',
                         lti_course_binding: binding)
      LtiLineItem.create!(lti_course_binding: binding,
                          gradable_type: LtiLineItem::TRAINING_PROGRESS_TYPE,
                          lineitem_id: 'http://lms/li/1')

      expect { binding.destroy }
        .to change(LtiContext, :count).by(-1)
        .and change(LtiLineItem, :count).by(-1)
    end
  end

  # `courses.flags[:canvas_integration]` is what the course page reads to decide
  # whether the course is LMS-linked (and to suppress the self-enroll alert). It
  # used to be written once at bind time and never cleared, so a course kept
  # reading as Canvas-linked after its binding moved away or was deleted.
  describe 'the linked-course flag' do
    let(:course) { create(:course) }
    let(:other_course) { create(:course, slug: 'School/Other_(2026)') }

    def flagged?(a_course)
      a_course.reload.flags[:canvas_integration] == true
    end

    it 'is set on the course a binding is linked to' do
      described_class.create!(base_attrs.merge(course:))
      expect(flagged?(course)).to be true
    end

    it 'is not set while the binding has no course' do
      described_class.create!(base_attrs)
      expect(flagged?(course)).to be false
    end

    it 'moves with the binding, clearing the course it left' do
      binding = described_class.create!(base_attrs.merge(course:))
      binding.update!(course: other_course)
      expect(flagged?(course)).to be false
      expect(flagged?(other_course)).to be true
    end

    it 'is cleared when the binding is unlinked from its course' do
      binding = described_class.create!(base_attrs.merge(course:))
      binding.update!(course: nil)
      expect(flagged?(course)).to be false
    end

    it 'is cleared when the binding is destroyed' do
      binding = described_class.create!(base_attrs.merge(course:))
      binding.destroy
      expect(flagged?(course)).to be false
    end

    it 'leaves unrelated course flags alone' do
      course.flags[:first_time_instructor] = true
      course.save!
      binding = described_class.create!(base_attrs.merge(course:))
      binding.destroy
      expect(course.reload.flags[:first_time_instructor]).to be true
    end
  end
end
