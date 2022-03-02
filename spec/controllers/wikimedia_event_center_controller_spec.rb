# frozen_string_literal: true

require 'rails_helper'

describe WikimediaEventCenterController, type: :request do
  let(:course) { create(:course) }
  let(:organizer) { create(:user) }
  let(:facilitator) { organizer }
  let(:non_organizer) { create(:user, username: 'RandomUser') }
  let(:secret) { 'SharedSecret' }
  let(:course_slug) { course.slug }

  before do
    allow(Features).to receive(:wiki_ed?).and_return(false)
    course.campaigns << Campaign.first
    JoinCourse.new(course: course, user: facilitator, role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
  end

  describe '#confirm_event_sync' do
    subject do
      post '/wikimedia_event_center/confirm_event_sync', params: {
        course_slug: course_slug,
        organizer_username: organizer.username,
        event_id: '12345',
        secret: secret,
        format: :json
      }
    end

    context 'everything is in order' do
      it 'enables event sync' do
        expect(course.flags[:event_sync]).to be_nil
        subject
        expect(course.reload.flags[:event_sync]).to eq('12345')
      end
    end

    context 'when the secret is incorrect' do
      let(:secret) { 'WrongSecret' }

      it 'returns an error code' do
        subject
        response_json = JSON.parse(response.body)
        expect(response_json['error_code']).to eq('invalid_secret')
      end
    end

    context 'when the course does not exist' do
      let(:course_slug) { 'not-a-course' }

      it 'returns an error code' do
        subject
        response_json = JSON.parse(response.body)
        expect(response_json['error_code']).to eq('course_not_found')
      end
    end

    context 'when the organizer is not part of the course' do
      let(:facilitator) { non_organizer }

      it 'returns an error code' do
        subject
        response_json = JSON.parse(response.body)
        expect(response_json['error_code']).to eq('not_organizer')
      end
    end

    context 'when the course already has participants' do
      before do
        JoinCourse.new(course: course, user: non_organizer, role: CoursesUsers::Roles::STUDENT_ROLE)
      end

      it 'returns an error code' do
        subject
        response_json = JSON.parse(response.body)
        expect(response_json['error_code']).to eq('already_in_use')
      end
    end

    context 'when the course already has event sync enabled' do
      before do
        course.flags[:event_sync] = '23456'
        course.save!
      end

      it 'returns an error code' do
        subject
        response_json = JSON.parse(response.body)
        expect(response_json['error_code']).to eq('sync_already_enabled')
      end
    end
  end

  describe '#update_event_participants' do
    let(:event_id) { '12345' }

    subject do
      post '/wikimedia_event_center/update_event_participants', params: {
        course_slug: course.slug,
        organizer_username: organizer.username,
        event_id: event_id,
        secret: secret,
        participant_usernames: usernames,
        format: :json
      }
    end

    before do
      course.flags[:event_sync] = '12345'
      course.save!
    end

    context 'when new usernames are sent' do
      # two real usernames, one non-existent username
      let(:usernames) { %w[RandomUser AnotherRandomUser DefinitelyNotARealUserAtAllEver] }

      it 'adds participants' do
        expect(course.students.count).to eq(0)
        VCR.use_cassette('wikimedia_event_center_controller_spec') do
          subject
        end
        expect(course.reload.students.count).to eq(2)
      end
    end

    context 'when the user list shrinks' do
      let(:usernames) { [] }

      before do
        JoinCourse.new(course: course, user: non_organizer, role: CoursesUsers::Roles::STUDENT_ROLE)
      end

      it 'removes participants' do
        expect(course.students.count).to eq(1)
        subject
        expect(course.reload.students.count).to eq(0)
      end
    end

    context 'when the course is already synced to another event' do
      let(:event_id) { '54321' }
      let(:usernames) { ['Ragesoss'] }

      it 'returns an error code' do
        subject
        response_json = JSON.parse(response.body)
        expect(response_json['error_code']).to eq('sync_not_enabled')
      end
    end
  end
end
