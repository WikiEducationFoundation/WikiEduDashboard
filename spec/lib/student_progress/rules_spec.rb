# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/student_progress/rules"

describe StudentProgress::Rules do
  let(:course) { create(:course) }
  let(:student) { create(:user) }
  let(:training) { create(:training_module, slug: 'a-training', kind: 0) }
  let(:exercise) { create(:training_module, slug: 'an-exercise', kind: 1) }

  describe '.training_complete?' do
    it 'is true once the module has a completion time' do
      tmu = TrainingModulesUsers.new(completed_at: 1.day.ago)
      expect(described_class.training_complete?(tmu)).to be(true)
    end

    it 'is false for a started module and for a missing record' do
      expect(described_class.training_complete?(TrainingModulesUsers.new)).to be(false)
      expect(described_class.training_complete?(nil)).to be(false)
    end
  end

  describe '.exercise_complete?' do
    it 'reads the per-course completion flag' do
      tmu = TrainingModulesUsers.new(flags: { course.id => { marked_complete: true } })
      expect(described_class.exercise_complete?(tmu, course)).to be(true)
    end

    it 'ignores completion recorded for a different course' do
      tmu = TrainingModulesUsers.new(flags: { (course.id + 1) => { marked_complete: true } })
      expect(described_class.exercise_complete?(tmu, course)).to be(false)
    end

    it 'counts a legacy top-level flag when there is no per-course entry' do
      tmu = TrainingModulesUsers.new(flags: { marked_complete: true })
      expect(described_class.exercise_complete?(tmu, course)).to be(true)
    end

    it 'prefers the per-course entry over a legacy top-level flag' do
      tmu = TrainingModulesUsers.new(flags: { marked_complete: true,
                                              course.id => { marked_complete: false } })
      expect(described_class.exercise_complete?(tmu, course)).to be(false)
    end

    it 'is false for a missing record' do
      expect(described_class.exercise_complete?(nil, course)).to be(false)
    end
  end

  describe '.module_complete?' do
    it 'uses the exercise flag for exercises, not the completion time' do
      tmu = TrainingModulesUsers.new(completed_at: 1.day.ago)
      expect(described_class.module_complete?(tmu, exercise, course)).to be(false)
    end

    it 'uses the completion time for trainings' do
      tmu = TrainingModulesUsers.new(completed_at: 1.day.ago)
      expect(described_class.module_complete?(tmu, training, course)).to be(true)
    end
  end

  describe '.page_created?' do
    it 'treats every status but does-not-exist as created' do
      statuses = AssignmentPipeline::SandboxStatuses
      expect(described_class.page_created?(statuses::DOES_NOT_EXIST)).to be(false)
      expect(described_class.page_created?(statuses::EXISTS_IN_USERSPACE)).to be(true)
      expect(described_class.page_created?(statuses::EXISTS_IN_MAINSPACE)).to be(true)
    end
  end

  describe '.review_complete?' do
    let(:review) do
      Assignment.create!(course:, user: student, wiki: course.home_wiki,
                         role: Assignment::Roles::REVIEWING_ROLE, article_title: 'Reviewed')
    end

    it 'is false for a review not marked complete and with no page' do
      expect(described_class.review_complete?(review)).to be(false)
    end

    it 'is true once the student marks it complete' do
      review.update_status(AssignmentPipeline::ReviewStatuses::PEER_REVIEW_COMPLETED)
      expect(described_class.review_complete?(review)).to be(true)
    end

    it 'is true once the review page exists' do
      review.update_sandbox_status(:review,
                                   AssignmentPipeline::SandboxStatuses::EXISTS_IN_USERSPACE)
      expect(described_class.review_complete?(review)).to be(true)
    end
  end
end
