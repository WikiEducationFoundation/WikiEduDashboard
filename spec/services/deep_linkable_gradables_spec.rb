# frozen_string_literal: true

require 'rails_helper'

describe DeepLinkableGradables do
  let(:course) { create(:course) }
  let!(:week) { create(:week, course:, order: 1) }
  let(:training_module) do
    create(:training_module, slug: 'get-started', name: 'Get started', kind: 0)
  end
  let(:exercise_module) do
    create(:training_module, slug: 'bibliography', name: 'Bibliography', kind: 1)
  end

  before do
    # Block.after_commit would queue the sync worker; stub so the synchronous
    # Sidekiq runner doesn't fire during setup.
    allow(LtiLineItemSyncWorker).to receive(:perform_in)
    allow(LtiLineItemSyncWorker).to receive(:perform_async)
  end

  subject(:gradables) { described_class.new(course).result }

  # Peer review is the one stage with no exercise module, so it never reached the
  # picker — and therefore couldn't become a Canvas column at all. The course's
  # expected-review count is what says the stage is part of the course.
  describe 'the peer-review stage' do
    def expect_reviews(count)
      course.flags[:peer_review_count] = count
      course.save!
    end

    it 'is not offered when the course expects no peer reviews' do
      expect(gradables.map(&:gradable_type)).not_to include(LtiLineItem::PEER_REVIEW_TYPE)
    end

    it 'is offered once the course expects peer reviews' do
      expect_reviews(2)
      stage = gradables.find { |g| g.gradable_type == LtiLineItem::PEER_REVIEW_TYPE }
      expect(stage).to be_present
      expect(stage.resource).to eq('PeerReview')
      expect(stage.gradable_id).to be_nil
    end

    # The stage has no exercise and no assigned training, so it is identified by
    # block title — the wizard's "Peer review two articles" and friends.
    it 'takes its due date from the peer-review timeline block' do
      expect_reviews(1)
      block = create(:block, week:, order: 5, title: 'Peer review two articles')

      stage = gradables.find { |g| g.gradable_type == LtiLineItem::PEER_REVIEW_TYPE }
      expect(stage.due_date).to eq(block.calculated_due_date)
    end

    # The stage spans the reviewing and the milestone that closes it; the deadline
    # is the end of the stage, not its start.
    it 'takes the last peer-review block when the stage spans several' do
      expect_reviews(1)
      create(:block, week:, order: 2, title: 'Peer review two articles')
      last_week = create(:week, course:, order: 7)
      milestone = create(:block, week: last_week, order: 0,
                                 title: 'Peer reviews are complete')

      stage = gradables.find { |g| g.gradable_type == LtiLineItem::PEER_REVIEW_TYPE }
      expect(stage.due_date).to eq(milestone.calculated_due_date)
    end

    # A real block on the wizard timeline, a week after the stage ends. Matching it
    # would push the deadline out by a week.
    it 'ignores a block that only mentions peer review later in its title' do
      expect_reviews(1)
      create(:block, week:, order: 2, title: 'Peer review two articles')
      create(:block, week: create(:week, course:, order: 9), order: 0,
                     title: 'Respond to your peer review')

      stage = gradables.find { |g| g.gradable_type == LtiLineItem::PEER_REVIEW_TYPE }
      expect(stage.due_date).to eq(Block.find_by(title: 'Peer review two articles')
                                        .calculated_due_date)
    end

    # A course can expect reviews without the timeline naming them; the column is
    # still worth offering, just without a deadline.
    it 'carries no due date when the timeline has no peer-review block' do
      expect_reviews(1)
      stage = gradables.find { |g| g.gradable_type == LtiLineItem::PEER_REVIEW_TYPE }
      expect(stage.due_date).to be_nil
    end

    # The picker's order is also the order Canvas creates the assignments in, so
    # appending the stage after the exercises misrepresented the sequence twice:
    # peer review read as the final assignment of the course.
    it 'sits in timeline order rather than last' do
      expect_reviews(1)
      early_week = create(:week, course:, order: 1)
      late_week = create(:week, course:, order: 9)
      create(:block, week: early_week, order: 0, title: 'Early exercise',
                     training_module_ids: [exercise_module.id])
      create(:block, week: create(:week, course:, order: 5), order: 0,
                     title: 'Peer review two articles')
      late_exercise = create(:training_module, slug: 'late-ex', name: 'Late exercise', kind: 1)
      create(:block, week: late_week, order: 0, title: 'Late exercise',
                     training_module_ids: [late_exercise.id])

      rollups = %w[WikipediaSetup TrainingProgress]
      timeline = gradables.reject { |g| rollups.include?(g.gradable_type) }
      expect(timeline.map(&:label))
        .to eq(['Wk1 Early exercise', DeepLinkableGradables::PEER_REVIEW_LABEL,
                'Wk9 Late exercise'])
    end

    it 'still goes last when the timeline has no peer-review block' do
      expect_reviews(1)
      create(:block, week: create(:week, course:, order: 9), order: 0, title: 'Late exercise',
                     training_module_ids: [exercise_module.id])

      expect(gradables.last.gradable_type).to eq(LtiLineItem::PEER_REVIEW_TYPE)
    end
  end

  it 'always offers the Wikipedia account setup indicator first' do
    expect(gradables.first.gradable_type).to eq(LtiLineItem::SETUP_TYPE)
    expect(gradables.first.label).to eq('Wikipedia account')
  end

  context 'with a training-only block and an exercise block' do
    let!(:training_block) do
      create(:block, week:, order: 0, title: 'Get started on Wikipedia',
                     training_module_ids: [training_module.id])
    end
    let!(:exercise_block) do
      create(:block, week:, order: 1, title: 'Find sources',
                     training_module_ids: [exercise_module.id],
                     content: '<p>Find three reliable sources.</p>')
    end

    it 'offers one option per exercise block, keyed Block:<id>' do
      exercise = gradables.find { |g| g.gradable_type == 'Block' }
      expect(exercise.gradable_id).to eq(exercise_block.id)
      expect(exercise.resource).to eq("Block:#{exercise_block.id}")
      expect(exercise.label).to eq('Wk1 Find sources')
    end

    it 'offers a single TrainingProgress rollup option' do
      rollup = gradables.select { |g| g.gradable_type == LtiLineItem::TRAINING_PROGRESS_TYPE }
      expect(rollup.length).to eq(1)
      expect(rollup.first.resource).to eq('TrainingProgress')
      expect(rollup.first.gradable_id).to be_nil
    end

    # Canvas needs a date on the imported assignment or the deadline reaches no
    # calendar and no To Do list. See the class comment for the per-gradable
    # policy — this is the exercise case, the block's own due date.
    it 'carries the exercise block due date' do
      exercise = gradables.find { |g| g.gradable_type == 'Block' }
      expect(exercise.due_date).to eq(exercise_block.calculated_due_date)
    end

    # The roll-up is complete only when every training is, so the last training
    # block's date is the column's.
    it 'carries the last training block due date on the rollup' do
      late_week = create(:week, course:, order: 4)
      late_training = create(:block, week: late_week, order: 0, title: 'Last training',
                                     training_module_ids: [training_module.id])

      rollup = gradables.find { |g| g.gradable_type == LtiLineItem::TRAINING_PROGRESS_TYPE }
      expect(rollup.due_date).to eq(late_training.calculated_due_date)
      expect(rollup.due_date).to be > training_block.calculated_due_date
    end

    # Connecting an account is a state a student reaches once and keeps, not work
    # due by a date; a deadline would mark them late for something unrepeatable.
    it 'leaves the setup indicator without a due date' do
      setup = gradables.find { |g| g.gradable_type == LtiLineItem::SETUP_TYPE }
      expect(setup.due_date).to be_nil
    end

    it 'does not offer a training-only block as its own exercise option' do
      block_ids = gradables.select { |g| g.gradable_type == 'Block' }.map(&:gradable_id)
      expect(block_ids).not_to include(training_block.id)
    end
  end

  context 'with exercise blocks created out of timeline order' do
    let!(:week2) { create(:week, course:, order: 2) }
    # Insertion order deliberately reversed: the week-2 block gets the
    # lower id, so default (id) ordering would list it first.
    let!(:later_block) do
      create(:block, week: week2, order: 0, title: 'Later exercise',
                     training_module_ids: [exercise_module.id])
    end
    let!(:early_block) do
      create(:block, week:, order: 0, title: 'Early exercise',
                     training_module_ids: [exercise_module.id])
    end

    it 'lists options in timeline order, not insertion order' do
      block_ids = gradables.select { |g| g.gradable_type == 'Block' }.map(&:gradable_id)
      expect(block_ids).to eq([early_block.id, later_block.id])
    end
  end

  context 'when the course has exercises but no training modules' do
    let!(:exercise_block) do
      create(:block, week:, order: 0, title: 'Find sources',
                     training_module_ids: [exercise_module.id])
    end

    it 'omits the TrainingProgress rollup' do
      expect(gradables.map(&:gradable_type)).not_to include(LtiLineItem::TRAINING_PROGRESS_TYPE)
    end
  end

  context 'with no gradable blocks at all' do
    let!(:plain_block) do
      create(:block, week:, order: 0, title: 'Read this', training_module_ids: [])
    end

    it 'offers only the setup indicator' do
      expect(gradables.map(&:gradable_type)).to eq([LtiLineItem::SETUP_TYPE])
    end
  end
end
