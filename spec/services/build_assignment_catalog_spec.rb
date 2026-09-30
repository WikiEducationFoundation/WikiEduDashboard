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

  # The test DB may already hold this real module.
  let(:continue_improving) do
    TrainingModule.find_by(slug: 'continue-improving-exercise') ||
      create(:training_module, slug: 'continue-improving-exercise', name: 'Keep going', kind: 1)
  end

  it 'lists modules in timeline order, then the article, without discussions' do
    create(:block, week: week_two, order: 0, training_module_ids: [exercise.id])
    create(:block, week: week_one, order: 0, training_module_ids: [training.id, discussion.id])

    expect(keys).to eq(%w[training-tr-a exercise-ex-a article])
  end

  it 'describes a module item with its kind, name and due date' do
    create(:block, week: week_one, order: 0, training_module_ids: [training.id])
    item = catalog.items.first
    expect([item.kind, item.title, item.training_module])
      .to eq(['training', 'Training A', training])
    expect(item.due_date).to eq(course.blocks.first.calculated_due_date)
  end

  it 'folds the exercises about the article into one article item, where the first one sits' do
    create(:block, week: week_one, order: 0, training_module_ids: [training.id])
    create(:block, week: week_one, order: 1, training_module_ids: [bibliography_exercise.id])
    create(:block, week: week_two, order: 0, training_module_ids: [exercise.id])
    create(:block, week: week_two, order: 1, training_module_ids: [continue_improving.id])

    expect(keys).to eq(%w[training-tr-a article exercise-ex-a])
    article = catalog.items.find { |item| item.key == 'article' }
    expect(article.training_modules).to eq([bibliography_exercise, continue_improving])
  end

  it 'lists the article on its own for a course with no article exercises' do
    fellows = create(:fellows_cohort)
    expect(keys(fellows)).to eq(%w[article])
    expect(catalog(fellows).items.first.training_modules).to eq([])
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

      expect(keys).to eq(%w[training-tr-a peer-review exercise-ex-a article])
    end

    it 'is included when a student has been assigned a review, even with no count set' do
      Assignment.create!(course:, user: student, wiki: course.home_wiki,
                         role: Assignment::Roles::REVIEWING_ROLE, article_title: 'Reviewed')
      expect(keys).to include('peer-review')
    end
  end
end
