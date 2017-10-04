# frozen_string_literal: true
require 'rails_helper'

describe CoursesUpdateController do
  before { stub_wiki_validation }

  describe '#update' do
    let(:submitted_1) { false }
    let(:submitted_2) { false }
    let!(:course) { create(:course, submitted: submitted_1) }
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
        start: 2.months.ago.beginning_of_day,
        end: 2.months.from_now.end_of_day,
        term: 'pizza',
        slug: 'food',
        subject: 'cooking',
        expected_students: 1,
        submitted: submitted_2,
        day_exceptions: '',
        weekdays: '0001000',
        no_day_exceptions: true }
    end
    before do
      allow(controller).to receive(:current_user).and_return(user)
      allow(controller).to receive(:user_signed_in?).and_return(true)
      allow_any_instance_of(WikiCourseEdits).to receive(:update_course)
    end

    it 'updates all values' do
      params = { id: course.slug, course: course_params }
      put :update, params: params, as: :json
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

    context 'setting passcode' do
      let(:course) { create(:course) }
      before { course.update_attribute(:passcode, nil) }
      it 'sets if it is nil and not in params' do
        params = { id: course.slug, course: { title: 'foo' } }
        put :update, params: params, as: :json
        expect(course.reload.passcode).to match(/[a-z]{8}/)
      end
    end

    describe 'toggling timeline' do
      it 'sets the course flag to true' do
        expect(course.flags[:timeline_enabled]).to be_nil
        params = { id: course.slug, course: { timeline_enabled: true } }
        put :update, params: params, as: :json
        expect(course.reload.flags[:timeline_enabled]).to eq(true)
      end

      it 'sets the course flag to false' do
        expect(course.flags[:timeline_enabled]).to be_nil
        params = { id: course.slug, course: { timeline_enabled: false } }
        put :update, params: params, as: :json
        expect(course.reload.flags[:timeline_enabled]).to eq(false)
      end
    end

    it 'raises if course is not found' do
      params = { id: 'peanut-butter', course: course_params }
      expect { put :update, params: params, as: :json }
        .to raise_error(ActionController::RoutingError)
    end

    it 'returns the new course as json' do
      params = { id: course.slug, course: course_params }
      put :update, params: params, as: :json
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
        put :update, params: params, as: :json
      end
    end

    context 'course is new' do
      let(:submitted_2) { true }
      it 'announces course and emails the instructor' do
        # FIXME: Remove workaround after Rails 5.0.1
        # See https://github.com/rails/rails/issues/26075
        request.content_type = 'application/json'
        expect_any_instance_of(WikiCourseEdits).to receive(:announce_course)
        expect(CourseSubmissionMailer).to receive(:send_submission_confirmation)
        params = { id: course.slug, course: course_params }
        put :update, params: params, as: :json
      end
    end
  end
end
