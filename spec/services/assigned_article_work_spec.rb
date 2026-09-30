# frozen_string_literal: true

require 'rails_helper'

describe AssignedArticleWork do
  let(:course) { create(:course) }
  let(:student) { create(:user, username: 'writer') }
  let(:wiki) { course.home_wiki }

  def assign(user: student, title: 'Chromatic aberration',
             role: Assignment::Roles::ASSIGNED_ROLE, article: nil)
    Assignment.create!(course:, user:, wiki:, role:, article_title: title, article:)
  end

  # The statuses live in assignment.flags under the pipeline's own key, which is
  # what CheckAssignmentStatus writes and AssignmentPipeline reads back.
  def mark_created(assignment, page)
    assignment.update_sandbox_status(page, AssignmentPipeline::SandboxStatuses::EXISTS_IN_USERSPACE)
  end

  def work_for(user = student)
    described_class.new(course:, user_ids: [user.id]).articles_for(user)
  end

  it 'lists the assigned article with a link to the live page' do
    assign
    article = work_for.first
    expect(article.title).to eq('Chromatic aberration')
    expect(article.url).to include('Chromatic_aberration')
  end

  # A reviewing assignment is the peer-review stage, reported by its own column.
  it 'ignores reviewing assignments' do
    assign(title: 'Mine', role: Assignment::Roles::ASSIGNED_ROLE)
    assign(title: 'Someone elses', role: Assignment::Roles::REVIEWING_ROLE)
    expect(work_for.map(&:title)).to eq(['Mine'])
  end

  describe 'the pages of the writing process' do
    it 'points at the bibliography, outline and draft, in that order' do
      assignment = assign
      pages = work_for.first.pages

      expect(pages.map(&:kind)).to eq(%i[bibliography outline draft])
      expect(pages.first.url).to eq("#{wiki.base_url}/wiki/#{assignment.bibliography_pagename}")
      expect(pages.second.url).to eq("#{wiki.base_url}/wiki/#{assignment.outline_pagename}")
      expect(pages.third.url).to eq(assignment.sandbox_url)
    end

    it 'reports nothing as created until the status says so' do
      assign
      expect(work_for.first.pages.map(&:created)).to all(be(false))
    end

    it 'reports a page as created once its status is set' do
      assignment = assign
      mark_created(assignment, :bibliography)

      pages = work_for.first.pages.index_by(&:kind)
      expect(pages[:bibliography].created).to be(true)
      expect(pages[:outline].created).to be(false)
    end

    # Any of the exists-* statuses means the student has started it; only
    # DOES_NOT_EXIST means they haven't.
    it 'counts a page moved to mainspace as created' do
      assignment = assign
      assignment.update_sandbox_status(:outline,
                                       AssignmentPipeline::SandboxStatuses::EXISTS_IN_MAINSPACE)
      expect(work_for.first.pages.find { |p| p.kind == :outline }.created).to be(true)
    end

    # Nothing drafts in a sandbox on these courses, so there is no draft to
    # point at.
    it 'leaves out the draft sandbox when the course edits live articles' do
      course.flags[:no_sandboxes] = true
      course.save!
      assign

      expect(work_for.first.pages.map(&:kind)).to eq(%i[bibliography outline])
    end
  end

  describe 'the live article' do
    it 'is not live until the article exists on the wiki' do
      assign
      expect(work_for.first.live).to be(false)
      expect(work_for.first.stats.characters).to eq(0)
    end

    it 'sums only the timeslices this student contributed to' do
      article = create(:article, title: 'Chromatic_aberration', wiki:)
      other = create(:user, username: 'classmate')
      assign(article:)
      ArticleCourseTimeslice.create!(course:, article:, character_sum: 400,
                                     references_count: 3, revision_count: 2,
                                     user_ids: [student.id],
                                     start: 2.days.ago, end: 1.day.ago)
      ArticleCourseTimeslice.create!(course:, article:, character_sum: 900,
                                     references_count: 9, revision_count: 5,
                                     user_ids: [other.id],
                                     start: 1.day.ago, end: Time.zone.now)

      stats = work_for.first.stats
      expect(work_for.first.live).to be(true)
      expect(stats.characters).to eq(400)
      expect(stats.references).to eq(3)
      expect(stats.revisions).to eq(2)
    end

    it 'adds up a student’s work across timeslices' do
      article = create(:article, title: 'Chromatic_aberration', wiki:)
      assign(article:)
      2.times do |i|
        ArticleCourseTimeslice.create!(course:, article:, character_sum: 150,
                                       references_count: 1, revision_count: 1,
                                       user_ids: [student.id],
                                       start: (i + 2).days.ago, end: (i + 1).days.ago)
      end

      expect(work_for.first.stats.characters).to eq(300)
      expect(work_for.first.stats.revisions).to eq(2)
    end
  end

  # The roster path: one instance covers every student, so the drill-down doesn't
  # run four queries per row.
  it 'indexes a whole roster by user' do
    classmate = create(:user, username: 'classmate')
    assign(title: 'Mine')
    assign(user: classmate, title: 'Theirs')

    work = described_class.new(course:, user_ids: [student.id, classmate.id])
    expect(work.articles_for(student).map(&:title)).to eq(['Mine'])
    expect(work.articles_for(classmate).map(&:title)).to eq(['Theirs'])
  end

  it 'is empty for a student with no assignment, and for no user at all' do
    work = described_class.new(course:, user_ids: [student.id])
    expect(work.articles_for(student)).to be_empty
    expect(work.articles_for(nil)).to be_empty
  end
end
