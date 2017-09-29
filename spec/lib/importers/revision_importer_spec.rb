# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/importers/revision_importer"
require "#{Rails.root}/lib/articles_courses_cleaner"

describe RevisionImporter do
  describe '.users_with_no_revisions' do
    let(:subject)   { RevisionImporter.new(Wiki.default_wiki) }
    let(:user)      { create(:user) }
    let(:course_1)  { create(:course, start: '2015-01-01', end: '2015-12-31') }
    let(:course_2)  { create(:course, start: '2016-01-01', end: '2016-12-31', slug: 'foo/course2') }

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
      result = RevisionImporter.new(Wiki.default_wiki, course_2).send(:users_with_no_revisions)
      expect(result).to include(user)
    end

    it 'does not return users who have revisions for the course' do
      result = RevisionImporter.new(Wiki.default_wiki, course_1).send(:users_with_no_revisions)
      expect(result).not_to include(user)
    end
  end
end
