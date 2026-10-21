# frozen_string_literal: true

require 'rails_helper'

describe SwitchCourseSandboxMode do
  let(:course) { create(:course, flags: {}) }
  let(:weeks) { (1..8).map { |n| create(:week, course:, order: n) } }

  # The three blocks a wizard-built, individual-work, sandbox-drafting course
  # has, at the weeks the wizard would have put them.
  def build_sandbox_timeline
    create(:block, week: weeks[2], title: 'Keeping track of your work', order: 1)
    create(:block, week: weeks[4], title: 'Start drafting your contributions', order: 1)
    create(:block, week: weeks[7], title: 'Begin moving your work to Wikipedia', order: 1)
  end

  def course_blocks
    Block.where(week_id: Week.where(course_id: course.id).select(:id))
  end

  def titles
    course_blocks.pluck(:title)
  end

  before { Tag.create(course_id: course.id, key: 'working_in_groups', tag: 'working_individually') }

  describe 'switching to no sandboxes' do
    subject(:service) { described_class.new(course, no_sandboxes: true) }

    before { build_sandbox_timeline }

    it 'sets the no_sandboxes flag' do
      service
      expect(course.reload.no_sandboxes?).to be true
    end

    it 'rewrites the sandboxes tag' do
      service
      expect(Tag.find_by(course_id: course.id, key: 'sandboxes').tag).to eq('no_sandboxes')
    end

    it 'removes the blocks that no longer apply' do
      service
      expect(titles).not_to include('Start drafting your contributions',
                                    'Begin moving your work to Wikipedia')
    end

    it 'adds the blocks for editing live articles' do
      service
      expect(titles).to include('Start editing your article',
                                'Drafting a new article in a sandbox',
                                'Publishing a new article')
    end

    it 'swaps the two variants of the same-titled block' do
      service
      keeping_track = course_blocks.find_by(title: 'Keeping track of your work')
      expect(keeping_track.training_module_ids).to eq([65])
    end

    it 'places a replacement in the week the block it replaces vacated' do
      service
      block = course_blocks.find_by(title: 'Start editing your article')
      expect(block.week_id).to eq(weeks[4].id)
    end

    it 'carries the catalog points onto the new block' do
      service
      block = course_blocks.find_by(title: 'Publishing a new article')
      expect(block.kind).to eq(Block::KINDS['assignment'])
    end

    it 'reports what it added and removed' do
      expect(service.removed_blocks.map { |b| b[:catalog_id] })
        .to contain_exactly('keeping_track_sandboxes', 'start_drafting_individually',
                            'moving_to_mainspace_individually')
      expect(service.added_blocks.map { |b| b[:catalog_id] })
        .to contain_exactly('keeping_track_no_sandboxes', 'start_editing_live',
                            'drafting_new_article_in_sandbox', 'publishing_new_article_live')
    end
  end

  describe 'switching back to sandboxes' do
    before do
      build_sandbox_timeline
      described_class.new(course, no_sandboxes: true)
    end

    it 'round-trips to the original block titles' do
      described_class.new(course.reload, no_sandboxes: false)
      expect(titles).to contain_exactly('Keeping track of your work',
                                        'Start drafting your contributions',
                                        'Begin moving your work to Wikipedia')
    end

    it 'clears the flag and rewrites the tag' do
      described_class.new(course.reload, no_sandboxes: false)
      expect(course.reload.no_sandboxes?).to be false
      expect(Tag.find_by(course_id: course.id, key: 'sandboxes').tag).to eq('yes_sandboxes')
    end
  end

  describe 'when a block has been retitled' do
    subject(:service) { described_class.new(course, no_sandboxes: true) }

    before do
      build_sandbox_timeline
      course_blocks.find_by(title: 'Start drafting your contributions')
                   .update(title: 'Start writing (see Canvas)')
    end

    it 'reports it as unmatched rather than guessing' do
      expect(service.unmatched.map { |b| b[:catalog_id] })
        .to eq(['start_drafting_individually'])
    end

    it 'leaves the retitled block in place' do
      service
      expect(titles).to include('Start writing (see Canvas)')
    end

    it 'still swaps everything it could match' do
      service
      expect(titles).to include('Start editing your article')
    end
  end

  describe 'when individual-vs-group work cannot be recovered' do
    subject(:service) { described_class.new(course, no_sandboxes: true) }

    # build_sandbox_timeline creates its blocks without training modules, so
    # TimelineGroupMode has nothing to go on either.
    before do
      Tag.find_by(course_id: course.id, key: 'working_in_groups').destroy
      build_sandbox_timeline
    end

    it 'reports the blocks that depend on it as unresolved' do
      expect(service.unresolved.map { |b| b[:catalog_id] })
        .to include('start_drafting_individually', 'start_drafting_in_groups',
                    'moving_to_mainspace_individually', 'moving_to_mainspace_in_groups')
    end

    it 'leaves those blocks alone instead of removing them' do
      service
      expect(titles).to include('Start drafting your contributions',
                                'Begin moving your work to Wikipedia')
    end

    it 'still switches the blocks that do not depend on it' do
      service
      expect(titles).to include('Start editing your article', 'Publishing a new article')
    end

    it 'still sets the flag and tag' do
      service
      expect(course.reload.no_sandboxes?).to be true
      expect(Tag.find_by(course_id: course.id, key: 'sandboxes').tag).to eq('no_sandboxes')
    end
  end

  describe 'when the tag is missing but the timeline shows the answer' do
    subject(:service) { described_class.new(course, no_sandboxes: true) }

    # Same situation as above, except the blocks still carry the training
    # modules the wizard gave them, which say which variant this course got.
    before do
      Tag.find_by(course_id: course.id, key: 'working_in_groups').destroy
      create(:block, week: weeks[2], title: 'Keeping track of your work', order: 1)
      create(:block, week: weeks[4], title: 'Start drafting your contributions',
                     training_module_ids: [31, 15], order: 1)
      create(:block, week: weeks[7], title: 'Begin moving your work to Wikipedia',
                     training_module_ids: [33], order: 1)
    end

    it 'infers group work from the timeline' do
      expect(service.inferred_group_mode).to eq('working_in_groups')
    end

    it 'resolves the group-dependent blocks instead of reporting them' do
      expect(service.unresolved).to be_empty
    end

    it 'removes the group variants it inferred' do
      service
      expect(titles).not_to include('Start drafting your contributions',
                                    'Begin moving your work to Wikipedia')
    end

    it 'prefers a recorded tag over the timeline when both are present' do
      Tag.create(course_id: course.id, key: 'working_in_groups', tag: 'working_individually')
      expect(service.inferred_group_mode).to be_nil
      expect(service.unresolved).to be_empty
    end
  end

  describe 'a course with no timeline' do
    subject(:service) { described_class.new(course, no_sandboxes: true) }

    it 'still sets the flag and tag, and changes no blocks' do
      service
      expect(course.reload.no_sandboxes?).to be true
      expect(service.added_blocks).to be_empty
      expect(service.removed_blocks).to be_empty
    end
  end
end
