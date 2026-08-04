# frozen_string_literal: true

require 'rails_helper'

describe AssignmentViewContext do
  let(:course) { create(:course) }
  let(:week) { create(:week, course: course, order: 2) }
  let(:exercise_module) do
    create(:training_module, slug: 'eval-ex', name: 'Evaluate Wikipedia', kind: 1,
                             settings: { 'sandbox_location' => 'Evaluate_an_Article' })
  end
  let(:block) do
    create(:block, week: week, order: 0, title: 'Evaluate Wikipedia',
                   training_module_ids: [exercise_module.id])
  end
  let(:binding) do
    LtiCourseBinding.create!(course: course, lms_id: 'p', lms_family: 'canvas',
                             lms_context_id: 'c-1', lms_resource_link_id: 'rl-1')
  end
  let(:line_item) do
    LtiLineItem.create!(lti_course_binding: binding, gradable_type: 'Block',
                        gradable_id: block.id, lineitem_id: 'li-1',
                        label: 'Wk2 Evaluate Wikipedia')
  end

  before { allow(LtiLineItemSyncWorker).to receive(:perform_in) }

  def mark_complete(user)
    tmu = TrainingModulesUsers.new(user:, training_module: exercise_module,
                                   completed_at: 1.day.ago)
    tmu.flags = { course.id => { marked_complete: true } }
    tmu.save!
  end

  def link_student(user, roles: ['vocab/membership#Learner'])
    LtiContext.create!(user:, lti_course_binding: binding, user_lti_id: "lti-#{user.id}",
                       lms_id: 'p', roles:, linked_at: Time.current)
  end

  describe '#exercise_url' do
    it 'is nil for sandbox-based exercises' do
      context = described_class.new(line_item:, user: create(:user), instructor: false)
      expect(context.exercise_url).to be_nil
    end

    context 'for a dedicated-page exercise (exercise_path in module settings)' do
      let(:exercise_module) do
        create(:training_module, slug: 'fact-check-ex', name: 'Fact verification', kind: 1,
                                 settings: { 'exercise_path' => 'verify_claim' })
      end

      it "is the exercise's in-app page on the bound course" do
        context = described_class.new(line_item:, user: create(:user), instructor: false)
        expect(context.exercise_url).to eq("/courses/#{course.slug}/verify_claim")
      end
    end
  end

  describe '#title' do
    it 'is the line item label' do
      context = described_class.new(line_item:, user: create(:user), instructor: false)
      expect(context.title).to eq('Wk2 Evaluate Wikipedia')
    end
  end

  describe '#student_panel' do
    let(:user) { create(:user, username: 'Stu Dent') }
    let(:context) { described_class.new(line_item:, user:, instructor: false) }

    it 'is incomplete with a sandbox link before the exercise is done' do
      row = context.student_panel
      expect(row.completed?).to be(false)
      expect(row.sandbox_url).to include('en.wikipedia.org')
      expect(row.sandbox_url).to include('User:Stu_Dent/Evaluate_an_Article')
    end

    it 'is complete once the exercise is marked complete' do
      mark_complete(user)
      expect(context.student_panel.completed?).to be(true)
    end
  end

  describe '#roster' do
    let(:instructor) { create(:user) }
    let(:context) { described_class.new(line_item:, user: instructor, instructor: true) }

    it 'lists linked students by Wikipedia username, with completion and sandbox links' do
      amy = create(:user, username: 'amy')
      zed = create(:user, username: 'zed')
      link_student(amy)
      link_student(zed)
      mark_complete(amy)

      rows = context.roster
      expect(rows.map(&:name)).to eq(%w[amy zed])
      expect(rows.first.completed?).to be(true)
      expect(rows.first.sandbox_url).to include('User:amy/Evaluate_an_Article')
      expect(rows.second.completed?).to be(false)
    end

    it 'excludes instructors from the roster' do
      student = create(:user, username: 'pupil')
      teacher = create(:user, username: 'prof')
      link_student(student)
      link_student(teacher, roles: ['vocab/membership#Instructor'])
      expect(context.roster.map(&:name)).to eq(['pupil'])
    end

    it 'excludes members who have not linked a Wikipedia account' do
      LtiContext.create!(lti_course_binding: binding, user_lti_id: 'lti-unlinked',
                         lms_id: 'p', roles: ['vocab/membership#Learner'])
      expect(context.roster).to be_empty
    end
  end

  # "Completed" tells an instructor nothing on an article-selection exercise;
  # which article each student took on is the whole point of the stage.
  describe 'an article-selection exercise' do
    let(:exercise_module) do
      create(:training_module, slug: 'choose-topic-from-list-exercise',
                               name: 'Choose your article from a list', kind: 1)
    end
    let(:student) { create(:user, username: 'chooser') }

    def assign_article(user, title, role)
      Assignment.create!(course:, user:, role:, article_title: title,
                         wiki: course.home_wiki)
    end

    it 'reports article assignments rather than completion' do
      expect(described_class.new(line_item:, user: student, instructor: false))
        .to be_article_selection
    end

    it 'is not an article-selection column for an ordinary exercise' do
      other = create(:training_module, slug: 'eval-ex-2', name: 'Evaluate', kind: 1)
      block.update!(training_module_ids: [other.id])
      expect(described_class.new(line_item:, user: student, instructor: false))
        .not_to be_article_selection
    end

    it "carries the student's editing assignments on their own panel" do
      assign_article(student, 'Chromatic aberration', Assignment::Roles::ASSIGNED_ROLE)

      row = described_class.new(line_item:, user: student, instructor: false).student_panel
      expect(row.assigned_articles.map(&:title)).to eq(['Chromatic aberration'])
      expect(row.assigned_articles.first.url).to include('Chromatic_aberration')
    end

    # A reviewing assignment is the peer-review stage — a different timeline
    # block. Listing it here would report an article the student is only
    # reviewing as one they chose to write.
    it 'leaves out reviewing assignments' do
      assign_article(student, 'Mine to write', Assignment::Roles::ASSIGNED_ROLE)
      assign_article(student, 'Someone elses', Assignment::Roles::REVIEWING_ROLE)

      row = described_class.new(line_item:, user: student, instructor: false).student_panel
      expect(row.assigned_articles.map(&:title)).to eq(['Mine to write'])
    end

    it 'lists every editing assignment when a student has more than one' do
      assign_article(student, 'First article', Assignment::Roles::ASSIGNED_ROLE)
      assign_article(student, 'Second article', Assignment::Roles::ASSIGNED_ROLE)

      row = described_class.new(line_item:, user: student, instructor: false).student_panel
      expect(row.assigned_articles.map(&:title))
        .to contain_exactly('First article', 'Second article')
    end

    # The state an instructor is looking for on this column.
    it 'is empty for a student who has not chosen yet' do
      row = described_class.new(line_item:, user: student, instructor: false).student_panel
      expect(row.assigned_articles).to be_empty
    end

    it 'carries each roster row its own articles' do
      amy = create(:user, username: 'amy')
      zed = create(:user, username: 'zed')
      link_student(amy)
      link_student(zed)
      assign_article(amy, 'Amys article', Assignment::Roles::ASSIGNED_ROLE)

      rows = described_class.new(line_item:, user: nil, instructor: true).roster
      expect(rows.first.assigned_articles.map(&:title)).to eq(['Amys article'])
      expect(rows.second.assigned_articles).to be_empty
    end

    # Ordinary columns must not pay for a query they don't use.
    it 'loads no assignments for a non-selection column' do
      other = create(:training_module, slug: 'eval-ex-3', name: 'Evaluate', kind: 1)
      block.update!(training_module_ids: [other.id])
      assign_article(student, 'Not shown here', Assignment::Roles::ASSIGNED_ROLE)

      row = described_class.new(line_item:, user: student, instructor: false).student_panel
      expect(row.assigned_articles).to be_empty
    end
  end
end
