# frozen_string_literal: true

require 'rails_helper'

describe CopyAvailableArticlesController, type: :request do
  let(:user) { create(:user) }
  let(:target) { create(:course, slug: 'School/Target_(Term)') }
  let(:source) { create(:course, slug: 'School/Source_(Term)') }
  let(:student) { create(:user, username: 'Student') }
  let(:params) { { course_slug: target.slug, source: source.slug, format: :json } }
  let(:response_body) { Oj.load(response.body) }

  def enroll(enrolled_user, course, role)
    create(:courses_user, user: enrolled_user, course:, role:)
  end

  before do
    stub_wiki_validation
    create(:assignment, course: source, user_id: nil, role: 0, wiki_id: 1,
                        article_title: 'Alpha_article', flags: { available_article: true })
    create(:assignment, course: source, user: student, role: 0, wiki_id: 1,
                        article_title: 'Beta_article')
    allow(UpdateAssignmentsWorker).to receive(:schedule_edits)
    allow(UpdateCourseWorker).to receive(:schedule_edits)
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
  end

  describe 'authorization on the target course' do
    it 'returns 401 when not signed in' do
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(nil)
      post '/copy_available_articles', params: params
      expect(response.status).to eq(401)
      expect(target.assignments).to be_empty
    end

    it 'returns 401 for a student of the target course' do
      enroll(user, target, CoursesUsers::Roles::STUDENT_ROLE)
      post '/copy_available_articles', params: params
      expect(response.status).to eq(401)
      expect(target.assignments).to be_empty
    end

    it 'allows an instructor of the target course' do
      enroll(user, target, CoursesUsers::Roles::INSTRUCTOR_ROLE)
      post '/copy_available_articles', params: params
      expect(response.status).to eq(200)
      expect(target.assignments.available.pluck(:article_title)).to eq(['Alpha_article'])
    end

    it 'allows an admin who is not enrolled' do
      allow_any_instance_of(ApplicationController).to receive(:current_user)
        .and_return(create(:admin))
      post '/copy_available_articles', params: params
      expect(response.status).to eq(200)
    end

    it 'returns 404 for an unknown target course' do
      post '/copy_available_articles', params: params.merge(course_slug: 'School/Nope_(Term)')
      expect(response.status).to eq(404)
    end
  end

  describe 'source course rules' do
    before { enroll(user, target, CoursesUsers::Roles::INSTRUCTOR_ROLE) }

    it 'accepts a public source the user is not enrolled in' do
      post '/copy_available_articles', params: params
      expect(response.status).to eq(200)
    end

    it 'accepts the source as a pasted course URL' do
      url = "https://dashboard.wikiedu.org/courses/#{source.slug}/articles/available"
      post '/copy_available_articles', params: params.merge(source: url)
      expect(response.status).to eq(200)
      expect(target.assignments.count).to eq(1)
    end

    it 'returns 404 for a private source the user is not a member of' do
      source.update(private: true)
      post '/copy_available_articles', params: params
      expect(response.status).to eq(404)
      expect(response_body['message'])
        .to eq(I18n.t('error_no_course.explanation', slug: source.slug))
      expect(target.assignments).to be_empty
    end

    it 'accepts a private source the user is enrolled in' do
      source.update(private: true)
      enroll(user, source, CoursesUsers::Roles::INSTRUCTOR_ROLE)
      post '/copy_available_articles', params: params
      expect(response.status).to eq(200)
    end

    it 'returns 404 for an unknown source' do
      post '/copy_available_articles', params: params.merge(source: 'School/Nope_(Term)')
      expect(response.status).to eq(404)
    end

    it 'returns 422 when the source is the target course' do
      post '/copy_available_articles', params: params.merge(source: target.slug)
      expect(response.status).to eq(422)
      expect(response_body['message']).to eq(I18n.t('error.invalid_assignment'))
    end
  end

  describe '#create' do
    before { enroll(user, target, CoursesUsers::Roles::INSTRUCTOR_ROLE) }

    it 'includes student-assigned articles when include_student_assigned is true' do
      post '/copy_available_articles', params: params.merge(include_student_assigned: 'true')
      expect(target.assignments.available.pluck(:article_title))
        .to contain_exactly('Alpha_article', 'Beta_article')
    end

    it 'responds with the counts and the refreshed assignments list' do
      post '/copy_available_articles', params: params
      expect(response_body['created']).to eq(1)
      expect(response_body['skipped']).to eq(0)
      expect(response_body['source']['slug']).to eq(source.slug)
      expect(response_body['course']['assignments'].map { |a| a['article_title'] })
        .to eq(['Alpha article'])
    end

    it 'schedules the on-wiki course and assignment updates once' do
      expect(UpdateAssignmentsWorker).to receive(:schedule_edits)
        .with(course: target, editing_user: user).once
      expect(UpdateCourseWorker).to receive(:schedule_edits)
        .with(course: target, editing_user: user).once
      post '/copy_available_articles', params: params
    end

    it 'does not schedule on-wiki updates when nothing was copied' do
      create(:assignment, course: target, user_id: nil, role: 0, wiki_id: 1,
                          article_title: 'Alpha_article', flags: { available_article: true })
      expect(UpdateAssignmentsWorker).not_to receive(:schedule_edits)
      post '/copy_available_articles', params: params
      expect(response_body['skipped']).to eq(1)
    end
  end

  describe '#preview' do
    before { enroll(user, target, CoursesUsers::Roles::INSTRUCTOR_ROLE) }

    it 'reports the counts without creating anything' do
      create(:assignment, course: target, user_id: nil, role: 0, wiki_id: 1,
                          article_title: 'Alpha_article', flags: { available_article: true })
      get '/copy_available_articles/preview', params: params.merge(include_student_assigned: 'true')
      expect(response.status).to eq(200)
      expect(response_body['count']).to eq(2)
      expect(response_body['already_present']).to eq(1)
      expect(response_body['source']['title']).to include(source.title)
      expect(target.assignments.count).to eq(1)
    end
  end
end
