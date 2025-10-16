# frozen_string_literal: true

require 'rails_helper'

describe CoursesUpdateController do
  before { stub_wiki_validation }
  
  describe '#update' do
    let(:submitted_1) { false }
    let(:submitted_2) { false }
    let!(:course) { create(:course, submitted: submitted_1, slug: slug_params) }
    let(:user) { create(:admin) }
    let!(:courses_user) do
      create(:courses_user,
             course_id: course.id,
             user_id: user.id,
             role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    end
    let(:course_params) do
      { title: 'New title',
        description: 'New description',
        start: Time.zone.parse('2015-01-05'),
        end: Time.zone.parse('2015-12-20').end_of_day,
        term: 'pizza',
        slug: 'food',
        subject: 'cooking',
        expected_students: 1,
        submitted: submitted_2,
        day_exceptions: '',
        weekdays: '0001000',
        no_day_exceptions: true,
        withdrawn: true,
        home_wiki_id: 1 }
    end

    before do
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
      allow_any_instance_of(ApplicationController).to receive(:user_signed_in?).and_return(true)
      allow_any_instance_of(WikiCourseEdits).to receive(:update_course)
    end

    it 'updates all values' do
      params = { id: course.slug, course: course_params }
      put "/courses/#{course.slug}", params: params, as: :json
      course_params.each do |key, value|
        # There's some variability the precision of datetimes between what
        # comes out of MySQL and a raw Ruby datetime object. So we add a bit
        # of imprecision to work around that.
        if key == :end
          expect(course.reload.send(key)).to be_within(1.second).of(value)
        else
          expect(course.reload.send(key)).to eq(value)
        end
      end
    end

    it 'includes the home wiki in courses wikis' do
      course_params[:wikis] = [{ language: 'de', project: 'wikipedia' }]
      params = { id: course.slug, course: course_params }
      put "/courses/#{course.slug}", params: params, as: :json
      expect(course.wikis.count).to eq(2)
    end

    it 'adds more than one wikis' do
      course_params[:wikis] = [{ language: 'de', project: 'wikipedia' }]
      params = { id: course.slug, course: course_params }
      course_params[:wikis].push(language: 'fr', project: 'wikipedia')
      put "/courses/#{course.slug}", params: params, as: :json
      expect(course.wikis.count).to eq(3)
    end

    it 'removes a wiki' do
      course_params[:wikis] = [{ language: 'de', project: 'wikipedia' }]
      params = { id: course.slug, course: course_params }
      put "/courses/#{course.slug}", params: params, as: :json
      expect(course.wikis.count).to eq(2)
      course.reload
      course_params[:wikis].pop
      put "/courses/#{course.slug}", params: params, as: :json
      expect(course.wikis.count).to eq(1)
    end

    it 'adds the incoming wiki and removes the deleted wiki' do
      course_params[:wikis] = [{ language: 'de', project: 'wikipedia' }]
      params = { id: course.slug, course: course_params }
      put "/courses/#{course.slug}", params: params, as: :json
      expect(course.wikis.count).to eq(2)
      course.reload
      course_params[:wikis][0][:language] = 'fr'
      put "/courses/#{course.slug}", params: params, as: :json
      expect(course.wikis.last.language).to eq('fr')
    end

    it 'adds namespaces' do
      course_params[:wikis] = [
        { language: 'en', project: 'wikipedia' },
        { language: 'en', project: 'wikibooks' }
      ]
      course_params[:namespaces] =
        ['en.wikipedia.org-namespace-0', 'en.wikibooks.org-namespace-102']
      params = { id: course.slug, course: course_params }
      put "/courses/#{course.slug}", params: params, as: :json
      expect(course.course_wiki_namespaces.count).to eq(2)
    end

    it 'deletes namespaces if corresponding wiki is deleted' do
      course_params[:wikis] = [
        { language: 'en', project: 'wikipedia' },
        { language: 'en', project: 'wikibooks' }
      ]
      course_params[:namespaces] =
        ['en.wikipedia.org-namespace-0', 'en.wikibooks.org-namespace-102']
      params = { id: course.slug, course: course_params }
      put "/courses/#{course.slug}", params: params, as: :json
      expect(course.course_wiki_namespaces.count).to eq(2)
      course.reload
      course_params[:wikis].pop
      put "/courses/#{course.slug}", params: params, as: :json
      expect(course.course_wiki_namespaces.count).to eq(1)
    end

    context 'setting passcode' do
      let(:course) { create(:course, slug: slug_params) }

      before do
        # skip validations here - some course types allow nil passcodes, some dont
        course.passcode = nil
        course.save(validate: false)
      end

      it 'sets randomly if it is nil and not in params' do
        params = { id: course.slug, course: { title: 'foo' } }
        put "/courses/#{course.slug}", params: params, as: :json
        expect(course.reload.passcode).to match(/[a-z]{8}/)
      end

      it 'does not update it if placeholder passcode is received' do
        params = { id: course.slug, course: { title: 'foo', passcode: '****' } }
        put "/courses/#{course.slug}", params: params, as: :json
        expect(course.reload.passcode).to be_nil
      end

      it 'updates it if new passcode is received' do
        params = { id: course.slug, course: { title: 'foo', passcode: 'newpasscode' } }
        put "/courses/#{course.slug}", params: params, as: :json
        expect(course.reload.passcode).to eq('newpasscode')
      end
    end

    describe 'toggling timeline' do
      it 'sets the course flag to true' do
        expect(course.flags[:timeline_enabled]).to be_nil
        params = { id: course.slug, course: { timeline_enabled: true } }
        put "/courses/#{course.slug}", params: params, as: :json
        expect(course.reload.flags[:timeline_enabled]).to eq(true)
      end

      it 'sets the course flag to false' do
        expect(course.flags[:timeline_enabled]).to be_nil
        params = { id: course.slug, course: { timeline_enabled: false } }
        put "/courses/#{course.slug}", params: params, as: :json
        expect(course.reload.flags[:timeline_enabled]).to eq(false)
      end
    end

    describe 'toggling disable student emails' do
      it 'sets the disable student emails flag to true' do
        expect(course.disable_student_emails?).to be false
        params = { id: course.slug, course: { disable_student_emails: true } }
        put "/courses/#{course.slug}", params: params, as: :json
        expect(course.reload.flags[:disable_student_emails]).to eq(true)
      end

      it 'sets the disable student emails flag to false' do
        expect(course.disable_student_emails?).to be false
        params = { id: course.slug, course: { disable_student_emails: false } }
        put "/courses/#{course.slug}", params: params, as: :json
        expect(course.reload.flags[:disable_student_emails]).to eq(false)
      end
    end

    describe 'updating "last_reviewed"' do
      it 'sets the timestamp and reviewer' do
        expect(course.flags['last_reviewed']).to be_nil
        params = {
          id: course.slug,
          course: { last_reviewed: { username: 'Ragesoss', timestamp: Time.zone.now } }
        }
        put "/courses/#{course.slug}", params: params, as: :json
        expect(course.reload.flags.dig('last_reviewed', 'username')).to eq('Ragesoss')
      end
    end

    it 'raises if course is not found' do
      params = { id: 'peanut-butter', course: course_params }
      expect { put "/courses/#{course.id}", params:, as: :json }
        .to raise_error(ActionController::RoutingError)
    end

    it 'returns the new course as json' do
      params = { id: course.slug, course: course_params }
      put "/courses/#{course.slug}", params: params, as: :json
      # created ats differ by milliseconds, so check relevant attrs
      expect(response.body['title']).to eq(course.reload.to_json['title'])
      expect(response.body['term']).to eq(course.reload.to_json['term'])
      expect(response.body['subject']).to eq(course.reload.to_json['subject'])
    end

    context 'course is not new' do
      let(:submitted_1) { true }
      let(:submitted_2) { true }

      it 'does not announce course' do
        expect_any_instance_of(WikiCourseEdits).not_to receive(:announce_course)
        params = { id: course.slug, course: course_params }
        put "/courses/#{course.slug}", params:, as: :json
      end
    end

    context 'course is new' do
      let(:submitted_2) { true }

      it 'announces course and emails the instructor' do
        # FIXME: Remove workaround after Rails 5.0.1
        # See https://github.com/rails/rails/issues/26075
        headers = { 'HTTP_ACCEPT' => 'application/json' }
        expect_any_instance_of(WikiCourseEdits).to receive(:announce_course)
        expect(CourseSubmissionMailer).to receive(:send_submission_confirmation)
        params = { id: course.slug, course: course_params }
        put "/courses/#{course.slug}", params:, headers:, as: :json
      end
    end
  end
end 

