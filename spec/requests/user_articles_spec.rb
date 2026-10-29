# frozen_string_literal: true

require 'rails_helper'

describe 'User articles and language statistics', type: :request do
  let(:student) { create(:user, username: 'StudentA') }
  let(:partner) { create(:user, username: 'StudentB') }
  let(:course) { create(:course, slug: 'Uni/Group_course_(Spring_2026)') }
  let(:article) { create(:article, title: 'Shared_article') }

  def json_for(path)
    get path
    JSON.parse(response.body)
  end

  describe 'GET /users/:username/user_articles.json' do
    context 'when user does not exist' do
      it 'returns 404 not found' do
        get '/users/nonexistent_user/user_articles.json'
        expect(response.status).to eq(404)
        expect(JSON.parse(response.body)['error']).to eq('User not found')
      end
    end

    context 'with group assignments and ACUWT data' do
      before do
        create(:courses_user, user: student, course:, role: CoursesUsers::Roles::STUDENT_ROLE,
                              character_sum_ms: 300, references_count: 1)
        create(:courses_user, user: partner, course:, role: CoursesUsers::Roles::STUDENT_ROLE,
                              character_sum_ms: 2700, references_count: 9)
        create(:articles_course, course:, article:, character_sum: 3000,
                                 references_count: 10, new_article: true,
                                 user_ids: [student.id, partner.id])

        # Individual per-user stats stored in timeslices
        create(:article_course_user_wiki_timeslice,
               user: student, course:, article:, wiki: course.home_wiki,
               character_sum: 300, references_count: 1, new_article: false)
        create(:article_course_user_wiki_timeslice,
               user: partner, course:, article:, wiki: course.home_wiki,
               character_sum: 2700, references_count: 9, new_article: true)
      end

      it 'reports individual per-user metrics for StudentA' do
        data = json_for('/users/StudentA/user_articles.json')
        course_data = data['articles_by_course'].first
        article_data = course_data['articles'].first

        expect(article_data['word_count']).to eq(WordCount.from_characters(300))
        expect(article_data['references_count']).to eq(1)
        expect(article_data['new_article']).to be(false)
        expect(course_data['word_count']).to eq(WordCount.from_characters(300))
        expect(course_data['references_count']).to eq(1)
      end

      it 'reports individual per-user metrics for StudentB' do
        data = json_for('/users/StudentB/user_articles.json')
        course_data = data['articles_by_course'].first
        article_data = course_data['articles'].first

        expect(article_data['word_count']).to eq(WordCount.from_characters(2700))
        expect(article_data['references_count']).to eq(9)
        expect(article_data['new_article']).to be(true)
        expect(course_data['word_count']).to eq(WordCount.from_characters(2700))
        expect(course_data['references_count']).to eq(9)
      end

      it 'does not include total_count or filtered_by_course in response' do
        data = json_for('/users/StudentA/user_articles.json')
        expect(data).not_to have_key('total_count')
        expect(data).not_to have_key('filtered_by_course')
      end

      it 'scopes the query by course_id' do
        sql_queries = []
        callback = lambda do |*, payload|
          sql = payload[:sql]
          sql_queries << sql if sql.include?('user_ids LIKE')
        end

        ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') do
          get '/users/StudentA/user_articles.json'
        end

        expect(sql_queries).to all(include('course_id'))
      end
    end

    context 'with a finalized course whose timeslices were purged' do
      let(:solo_article) { create(:article, title: 'Solo_article') }

      before do
        course.update(flags: { finalized: true })
        create(:courses_user, user: student, course:, role: CoursesUsers::Roles::STUDENT_ROLE,
                              character_sum_ms: 800, references_count: 3)
        create(:courses_user, user: partner, course:, role: CoursesUsers::Roles::STUDENT_ROLE)
        create(:articles_course, course:, article: solo_article, character_sum: 500,
                                 references_count: 2, new_article: true, user_ids: [student.id])
        create(:articles_course, course:, article:, character_sum: 3000, references_count: 10,
                                 user_ids: [student.id, partner.id])
        # The purge keeps only the ACUWT records of deleted articles.
        create(:article_course_user_wiki_timeslice,
               user: student, course:, wiki: course.home_wiki, character_sum: 300,
               article: create(:article, title: 'Deleted_article', deleted: true))
      end

      it 'attributes ArticlesCourses stats to the sole editor instead of zero' do
        articles = json_for('/users/StudentA/user_articles.json')['articles_by_course']
                   .first['articles']
        solo = articles.find { |a| a['title'] == 'Solo_article' }

        expect(solo['word_count']).to eq(WordCount.from_characters(500))
        expect(solo['references_count']).to eq(2)
        expect(solo['new_article']).to be(true)
      end

      it 'leaves shared article stats blank' do
        articles = json_for('/users/StudentA/user_articles.json')['articles_by_course']
                   .first['articles']
        shared = articles.find { |a| a['title'] == 'Shared_article' }

        expect(shared['word_count']).to be_nil
        expect(shared['references_count']).to be_nil
      end
    end

    context 'when user is only an instructor in a course' do
      let(:taught_course) { create(:course, slug: 'Uni/Taught_course') }
      let(:taught_article) { create(:article, title: 'Instructor_edit') }

      before do
        create(:courses_user, user: student, course: taught_course,
                              role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
        create(:articles_course, course: taught_course, article: taught_article,
                                 character_sum: 500, user_ids: [student.id])
      end

      it 'excludes courses where user had only an instructor role' do
        data = json_for('/users/StudentA/user_articles.json')
        expect(data['articles_by_course']).to be_empty
      end
    end

    context 'without ACUWT data (legacy fallback)' do
      context 'when the user is the sole editor of the article' do
        before do
          create(:courses_user, user: student, course:, role: CoursesUsers::Roles::STUDENT_ROLE,
                                character_sum_ms: 500, references_count: 2)
          create(:articles_course, course:, article:, character_sum: 500,
                                   references_count: 2, new_article: true,
                                   user_ids: [student.id])
        end

        it 'attributes ArticlesCourses stats directly to the user' do
          data = json_for('/users/StudentA/user_articles.json')
          course_data = data['articles_by_course'].first
          article_data = course_data['articles'].first

          expect(article_data['word_count']).to eq(WordCount.from_characters(500))
          expect(article_data['references_count']).to eq(2)
          expect(article_data['new_article']).to be(true)
          expect(course_data['word_count']).to eq(WordCount.from_characters(500))
          expect(course_data['references_count']).to eq(2)
        end
      end

      context 'when multiple users edited the article (shared article)' do
        before do
          create(:courses_user, user: student, course:, role: CoursesUsers::Roles::STUDENT_ROLE,
                                character_sum_ms: 300, references_count: 1)
          create(:courses_user, user: partner, course:, role: CoursesUsers::Roles::STUDENT_ROLE,
                                character_sum_ms: 2700, references_count: 9)
          create(:articles_course, course:, article:, character_sum: 3000,
                                   references_count: 10, new_article: true,
                                   user_ids: [student.id, partner.id])
        end

        it 'takes course header totals from CoursesUsers and leaves shared article stats blank' do
          data_a = json_for('/users/StudentA/user_articles.json')
          course_a = data_a['articles_by_course'].first
          article_a = course_a['articles'].first

          expect(course_a['word_count']).to eq(WordCount.from_characters(300))
          expect(course_a['references_count']).to eq(1)
          expect(article_a['word_count']).to be_nil
          expect(article_a['references_count']).to be_nil
          expect(article_a['new_article']).to be(false)

          data_b = json_for('/users/StudentB/user_articles.json')
          course_b = data_b['articles_by_course'].first
          article_b = course_b['articles'].first

          expect(course_b['word_count']).to eq(WordCount.from_characters(2700))
          expect(course_b['references_count']).to eq(9)
          expect(article_b['word_count']).to be_nil
          expect(article_b['references_count']).to be_nil
          expect(article_b['new_article']).to be(false)
        end
      end

      context 'with an untracked article' do
        let(:untracked_article) { create(:article, title: 'Untracked_article') }

        before do
          create(:courses_user, user: student, course:, role: CoursesUsers::Roles::STUDENT_ROLE,
                                character_sum_ms: 500, references_count: 2)
          create(:articles_course, course:, article:, character_sum: 500,
                                   references_count: 2, user_ids: [student.id])
          create(:articles_course, course:, article: untracked_article, character_sum: 1200,
                                   tracked: false, user_ids: [student.id])
        end

        it 'excludes untracked articles from user articles' do
          data = json_for('/users/StudentA/user_articles.json')
          course_data = data['articles_by_course'].first
          titles = course_data['articles'].pluck('title')

          expect(titles).to include('Shared_article')
          expect(titles).not_to include('Untracked_article')
          expect(course_data['articles_edited']).to eq(1)
        end
      end
    end
  end

  describe 'GET /users/:username/stats.json (get_articles_by_language)' do
    let(:es_wiki) { create(:wiki, language: 'es', project: 'wikipedia') }
    let(:es_course) { create(:course, slug: 'Uni/Spanish_course', home_wiki: es_wiki) }
    let(:es_article) { create(:article, title: 'Articulo_es', wiki: es_wiki) }

    before do
      stub_wiki_validation
      create(:courses_user, user: student, course:, role: CoursesUsers::Roles::STUDENT_ROLE,
                            character_sum_ms: 1000, references_count: 3)
      create(:courses_user, user: student, course: es_course,
                            role: CoursesUsers::Roles::STUDENT_ROLE,
                            character_sum_ms: 2000, references_count: 5)
      create(:articles_course, course:, article:, character_sum: 1000, user_ids: [student.id])
      create(:articles_course, course: es_course, article: es_article, character_sum: 2000,
                               user_ids: [student.id])
    end

    it 'groups language contributions by course home wiki' do
      stats = json_for('/users/StudentA/stats.json')
      by_lang = stats['articles_by_language']

      expect(by_lang.pluck('language')).to contain_exactly('en', 'es')
      es_stat = by_lang.find { |s| s['language'] == 'es' }
      expect(es_stat['word_count']).to eq('386')
      expect(es_stat['references_count']).to eq('5')
      expect(es_stat['article_count']).to eq(1)
    end
  end
end
