# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join('lib/importers/revision_importer')
require Rails.root.join('lib/articles_courses_cleaner')

describe RevisionImporter do
  describe '.users_with_no_revisions' do
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

    before do
      ArticlesCourses.update_from_course(course_1)
      ArticlesCourses.update_from_course(course_2)
      CoursesUsers.all.collect(&:update_cache)
    end

    it 'returns users who have no revisions for the given course' do
      result = described_class.new(Wiki.default_wiki, course_2).send(:users_with_no_revisions)
      expect(result).to include(user)
    end

    it 'does not return users who have revisions for the course' do
      result = described_class.new(Wiki.default_wiki, course_1).send(:users_with_no_revisions)
      expect(result).not_to include(user)
    end
  end

  describe '#import_revisions_for_course' do
    let(:course) { create(:course, start: '2018-01-01', end: '2018-12-31') }
    let(:user) { create(:user, username: 'Ragesoss') }
    let(:article) { create(:article, title: 'Stray_Cats', mw_page_id: 164007, wiki: home_wiki) }
    let(:home_wiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
    let(:subject) do
      described_class.new(home_wiki, course).import_revisions_for_course(all_time: false)
    end
    let(:revision_count) { 0 }

    before do
      create(:courses_user, course:, user:, revision_count:)
    end

    context 'when there are no edits' do
      it 'imports all edits' do
        expect(Revision.count).to eq(0)
        VCR.use_cassette 'revision_importer/all' do
          subject
        end
        expect(Revision.count).to be > 77
      end
    end

    context 'when there already some edits' do
      let(:revision_count) { 1 }

      before do
        Revision.create(user:, date: 'Fri, 27 Jul 2018 05:09:32 UTC +00:00', wiki: home_wiki,
                        article:, mw_page_id: 164007, mw_rev_id: 852177599)
      end

      it 'only imports newer edits' do
        expect(Revision.count).to eq(1)
        VCR.use_cassette 'revision_importer/newer' do
          subject
        end
        expect(Revision.count).to be > 54
      end
    end

    context 'when an article with the same mw_page_id exists for a different wiki' do
      let(:course) { create(:course, start: '2021-04-28', end: '2021-04-30') }
      let(:user) { create(:user, username: 'דויד פון תמר') }
      let(:home_wiki) { Wiki.new(language: 'he', project: 'wikipedia', id: 24) }
      let(:he_wiki_page) do
        create(:article, title: 'מזנון', namespace: 3, mw_page_id: 13822, wiki: home_wiki)
      end
      let(:it_wikiquote) { Wiki.new(language: 'it', project: 'wikiquote', id: 193) }
      let(:it_wikiquote_page) do
        create(:article, title: 'CoB', namespace: 3, mw_page_id: 13822, wiki: it_wikiquote)
      end

      it 'associates revisions with the correct article' do
        # This replicates a bug on P & E Dashboard would occur before
        # the fix in c6f89b6d53878827f24efa8484a260939271809d
        VCR.use_cassette 'article_collision' do
          he_wiki_page
          it_wikiquote_page
          subject
          imported_rev = Revision.find_by(mw_page_id: 13822, wiki_id: home_wiki.id)
          expect(imported_rev.article_id).not_to eq(it_wikiquote_page.id)
        end
      end
    end

    context 'when there are edits to articles with four-byte unicode characters in the title' do
      # Workaround for # https://github.com/WikiEducationFoundation/WikiEduDashboard/issues/1744
      let(:home_wiki) { Wiki.new(language: 'zh', project: 'wikipedia', id: 999) }
      let(:course) { create(:course, start: '2019-04-30', end: '2019-05-02') }

      let(:user) { create(:user, username: 'Elmond') }

      it 'handles revisions with four-byte unicode characters' do
        VCR.use_cassette 'four-byte-unicode' do
          expect(Article.exists?(title: CGI.escape('黃𨥈瑩'))).to be(false)
          subject
          expect(Article.exists?(title: CGI.escape('黃𨥈瑩'))).to be(true)
        end
      end
    end
  end
end
