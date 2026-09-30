# frozen_string_literal: true

require 'rails_helper'

describe BuildAssignmentCatalog do
  let(:course) { create(:course) }
  let(:week_one) { create(:week, course:, order: 0) }
  let(:week_two) { create(:week, course:, order: 1) }
  let(:student) { create(:user) }
  let(:training) { create(:training_module, slug: 'tr-a', name: 'Training A', kind: 0) }
  let(:exercise) { create(:training_module, slug: 'ex-a', name: 'Exercise A', kind: 1) }
  let(:discussion) { create(:training_module, slug: 'disc-a', name: 'Discussion', kind: 2) }
  let(:bibliography_exercise) do
    create(:training_module, slug: 'bib-ex', name: 'Bibliography', kind: 1,
                             settings: { 'assignment_sandbox_location' => 'Bibliography' })
  end

  def catalog(for_course = course)
    roster = StudentProgress::Roster.new(course: for_course, user_ids: [student.id])
    described_class.new(roster:, timeline: StudentProgress::Timeline.new(roster))
  end

  def keys(for_course = course)
    catalog(for_course).items.map(&:key)
  end

  it 'lists modules in timeline order, then the article stages, without discussions' do
    create(:block, week: week_two, order: 0, training_module_ids: [exercise.id])
    create(:block, week: week_one, order: 0, training_module_ids: [training.id, discussion.id])

    expect(keys).to eq(%w[training-tr-a exercise-ex-a article-selection article-bibliography
                          article-outline article-draft article-live])
  end

  it 'describes a module item with its kind, name and due date' do
    create(:block, week: week_one, order: 0, training_module_ids: [training.id])
    item = catalog.items.first
    expect([item.kind, item.title, item.training_module])
      .to eq(['training', 'Training A', training])
    expect(item.due_date).to eq(course.blocks.first.calculated_due_date)
  end

  it 'lets an exercise about an article stage stand in for that stage' do
    create(:block, week: week_one, order: 0, training_module_ids: [bibliography_exercise.id])

    expect(keys).to include('exercise-bib-ex')
    expect(keys).not_to include('article-bibliography')
    expect(catalog.items.first.article_stage).to eq(:bibliography)
  end

  it 'leaves out bibliography and outline outside the classroom program' do
    fellows = create(:fellows_cohort)
    expect(keys(fellows)).to eq(%w[article-selection article-draft article-live])
  end

  it 'leaves out the draft stage for a no-sandboxes course' do
    course.update!(flags: { no_sandboxes: true })
    expect(keys).not_to include('article-draft')
  end

  describe 'peer review' do
    it 'is left out when reviews are neither expected nor assigned' do
      expect(keys).not_to include('peer-review')
    end

    it 'is included, at its timeline block, when the course expects reviews' do
      course.update!(flags: { peer_review_count: 1 })
      create(:block, week: week_one, order: 0, training_module_ids: [training.id])
      create(:block, week: week_one, order: 1, title: 'Peer review an article',
                     training_module_ids: [])
      create(:block, week: week_two, order: 0, training_module_ids: [exercise.id])

      expect(keys.first(3)).to eq(%w[training-tr-a peer-review exercise-ex-a])
    end

    it 'is included when a student has been assigned a review, even with no count set' do
      Assignment.create!(course:, user: student, wiki: course.home_wiki,
                         role: Assignment::Roles::REVIEWING_ROLE, article_title: 'Reviewed')
      expect(keys).to include('peer-review')
    end
  end
end
