# frozen_string_literal: true

require 'rails_helper'

describe PurgeCoursesController, type: :controller do
  render_views

  let(:admin) { create(:admin) }
  let(:course) do
    create(:course, slug: 'School/Old_(Term)', start: 2.years.ago, end: 1.year.ago,
                    flags: { purgeable: true })
  end

  before do
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin)
    allow(PurgeCourseTimeslicesWorker).to receive(:schedule_purge)
  end

  describe 'GET #show' do
    it 'shows the checks and the purge button for a course that can be purged' do
      get :show, params: { course_id: course.id }
      expect(response.body).to include('Ended more than 6 months ago')
      expect(response.body).to include('id="purge_course"')
      expect(response.body).not_to include('✗')
    end

    it 'marks the failed checks, still offering the purge button' do
      course.update(needs_update: true)
      get :show, params: { course_id: course.id }
      expect(response.body.scan('✗').size).to eq(1)
      expect(response.body).to include('id="purge_course"')
    end

    it 'says when the course does not exist' do
      get :show, params: { course_id: 0 }
      expect(response.body).to include('Course not found')
    end
  end

  describe 'POST #purge' do
    it 'queues the purge for a course that can be purged' do
      post :purge, params: { course_id: course.id }
      expect(PurgeCourseTimeslicesWorker).to have_received(:schedule_purge).with(course)
      expect(flash[:notice]).to eq('Purge queued')
    end

    it 'does not queue the purge for a course that fails a check' do
      course.update(flags: { finalized: true })
      post :purge, params: { course_id: course.id }
      expect(PurgeCourseTimeslicesWorker).not_to have_received(:schedule_purge)
      expect(flash[:error]).to eq('Course not eligible: Purgeable flag set, Not already finalized')
    end
  end

  it 'is only for admins' do
    allow_any_instance_of(ApplicationController).to receive(:current_user)
      .and_return(create(:user))
    get :show
    expect(response.status).to eq(401)
  end
end
