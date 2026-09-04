# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/importers/article_importer"

describe CopyAvailableArticles do
  let(:source) { create(:course, slug: 'School/Source_(Term)') }
  let(:target) { create(:course, slug: 'School/Target_(Term)') }
  let(:student) { create(:user, username: 'Student') }
  let(:es_wiki) { create(:wiki, language: 'es', project: 'wikipedia') }

  def add_available(course, title, wiki_id: 1, article_id: nil)
    create(:assignment, course:, user_id: nil, role: 0, wiki_id:, article_id:,
                        article_title: title, flags: { available_article: true })
  end

  def add_claimed(course, title, wiki_id: 1)
    create(:assignment, course:, user: student, role: 0, wiki_id:, article_title: title)
  end

  before { stub_wiki_validation }

  describe 'default copy' do
    before do
      add_available(source, 'Alpha_article', article_id: 5)
      add_claimed(source, 'Beta_article')
    end

    it 'copies only unclaimed Available Articles' do
      described_class.new(source:, target:)
      expect(target.assignments.pluck(:article_title)).to eq(['Alpha_article'])
    end

    it 'creates the copy as an Available Article with the source attributes' do
      described_class.new(source:, target:)
      copied = target.assignments.first
      expect(copied.user_id).to be_nil
      expect(copied.role).to eq(Assignment::Roles::ASSIGNED_ROLE)
      expect(copied.flags[:available_article]).to be(true)
      expect(copied.article_id).to eq(5)
      expect(copied.wiki_id).to eq(1)
    end

    it 'reports the counts' do
      service = described_class.new(source:, target:)
      expect([service.source_count, service.created_count, service.skipped_count]).to eq([1, 1, 0])
    end

    it 'does not call the wiki API' do
      expect(ArticleImporter).not_to receive(:new)
      described_class.new(source:, target:)
    end
  end

  describe 'include_student_assigned' do
    it 'also copies articles students were assigned, as Available Articles' do
      add_available(source, 'Alpha_article')
      add_claimed(source, 'Beta_article')
      described_class.new(source:, target:, include_student_assigned: true)
      expect(target.assignments.available.pluck(:article_title))
        .to contain_exactly('Alpha_article', 'Beta_article')
    end

    it 'deduplicates an article present both as available and as claimed' do
      add_available(source, 'Alpha_article')
      add_claimed(source, 'Alpha_article')
      service = described_class.new(source:, target:, include_student_assigned: true)
      expect(service.source_count).to eq(1)
      expect(target.assignments.count).to eq(1)
    end

    it 'excludes peer review assignments' do
      create(:assignment, course: source, user: student, role: 1, wiki_id: 1,
                          article_title: 'Reviewed_article')
      described_class.new(source:, target:, include_student_assigned: true)
      expect(target.assignments).to be_empty
    end
  end

  describe 'articles already in the target' do
    before do
      add_available(source, 'Alpha_article')
      add_available(source, 'Gamma_article')
      add_available(target, 'Alpha_article')
    end

    it 'skips them and reports them as skipped' do
      service = described_class.new(source:, target:)
      expect(target.assignments.pluck(:article_title))
        .to contain_exactly('Alpha_article', 'Gamma_article')
      expect([service.created_count, service.skipped_count]).to eq([1, 1])
    end

    it 'treats the same title on a different wiki as a different article' do
      add_available(source, 'Alpha_article', wiki_id: es_wiki.id)
      described_class.new(source:, target:)
      expect(target.assignments.where(article_title: 'Alpha_article').pluck(:wiki_id))
        .to contain_exactly(1, es_wiki.id)
    end

    it 'reports counts without writing anything on a dry run' do
      service = described_class.new(source:, target:, dry_run: true)
      expect([service.source_count, service.skipped_count, service.created_count]).to eq([2, 1, 0])
      expect(target.assignments.count).to eq(1)
    end
  end

  it 'skips a title that no longer passes validation instead of raising' do
    assignment = add_available(source, 'Alpha_article')
    assignment.update_column(:article_title, 'Special:Contributions') # rubocop:disable Rails/SkipsModelValidations
    service = described_class.new(source:, target:)
    expect(service.skipped_count).to eq(1)
    expect(target.assignments).to be_empty
  end
end
