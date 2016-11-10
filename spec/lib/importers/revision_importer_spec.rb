# frozen_string_literal: true
require 'rails_helper'
require "#{Rails.root}/lib/importers/revision_importer"
require "#{Rails.root}/lib/legacy_courses/legacy_course_importer"
require "#{Rails.root}/lib/articles_courses_cleaner"

describe RevisionImporter do
  describe '.users_with_no_revisions' do
    let(:subject)   { RevisionImporter.new(Wiki.default_wiki) }
    let(:user)      { create(:user) }
    let(:course_1)  { create(:course, start: '2015-01-01', end: '2015-12-31') }
    let(:course_2)  { create(:course, start: '2016-01-01', end: '2016-12-31') }

    let!(:cu) do
      create(:courses_user, course_id: course_1.id, user_id: user.id,
                            role: CoursesUsers::Roles::STUDENT_ROLE)
    end
    let!(:cu2) do
      create(:courses_user, course_id: course_2.id, user_id: user.id,
                            role: CoursesUsers::Roles::STUDENT_ROLE)
    end

    let(:article)   { create(:article) }
    let!(:revision) do
      create(:revision, user_id: user.id, article_id: article.id, date: course_1.start + 1.month)
    end

    before { CoursesUsers.all.collect(&:update_cache) }

    it 'returns users who have no revisions for the given course' do
      expect(subject.send(:users_with_no_revisions, course_2)).to include(user)
    end

    it 'does not return users who have revisions for the course' do
      expect(subject.send(:users_with_no_revisions, course_1)).not_to include(user)
    end
  end

  describe '.move_or_delete_revisions' do
    it 'updates the article_id for a moved revision' do
      # https://en.wikipedia.org/w/index.php?title=Selfie&oldid=547645475
      create(:revision,
             mw_rev_id: 547645475,
             mw_page_id: 1,
             article_id: 1) # Not the actual article_id
      revision = Revision.all
      RevisionImporter.new(Wiki.default_wiki).move_or_delete_revisions(revision)
      article = Revision.find_by(mw_rev_id: 547645475).article
      expect(article.mw_page_id).to eq(38956275)
      expect(Article.exists?(mw_page_id: 38956275)).to be true
    end
  end
end
