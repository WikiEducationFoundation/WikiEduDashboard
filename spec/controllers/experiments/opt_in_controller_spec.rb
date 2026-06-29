# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/experiments/opt_in_experiment"

describe Experiments::OptInController, type: :controller do
  let(:course) { create(:course, start: Date.new(2026, 9, 1)) }
  let(:student) { create(:user) }
  let(:slug) { Fall2026ResearchExperiment::SLUG }
  let!(:courses_user) do
    create(:courses_user, course:, user: student, role: CoursesUsers::Roles::STUDENT_ROLE)
  end

  before do
    allow(Features).to receive(:wiki_ed?).and_return(true)
    allow(Features).to receive(:disable_wiki_output?).and_return(true)
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(student)
  end

  describe 'GET #show' do
    it 'reports needs_response for a participating course' do
      create(:tag, course:, tag: "#{slug}_opted_in")
      get :show, params: { course_id: course.id }
      json = response.parsed_body
      expect(json['experiment_slug']).to eq(slug)
      expect(json['needs_response']).to be true
      expect(json['copy']).to include('message', 'opt_in', 'opt_out')
    end

    it 'does not need a response when the course is not participating' do
      get :show, params: { course_id: course.id }
      expect(response.parsed_body['needs_response']).to be false
    end
  end

  describe 'POST #opt_in' do
    before { create(:tag, course:, tag: "#{slug}_opted_in") }

    it 'records the opt-in' do
      post :opt_in, params: { experiment_slug: slug, course_id: course.id }
      record = ExperimentCoursesUser.find_by(courses_user:, experiment_slug: slug)
      expect(record.opted_in?).to be true
    end

    it 'passes through a reauth_required result' do
      allow_any_instance_of(InstallExperimentUserscript).to receive(:status)
        .and_return(:reauth_required)
      post :opt_in, params: { experiment_slug: slug, course_id: course.id }
      expect(response.parsed_body['reauth_required']).to be true
    end
  end

  describe 'POST #opt_out' do
    before { create(:tag, course:, tag: "#{slug}_opted_in") }

    it 'records the opt-out' do
      post :opt_out, params: { experiment_slug: slug, course_id: course.id }
      record = ExperimentCoursesUser.find_by(courses_user:, experiment_slug: slug)
      expect(record.opted_out?).to be true
    end
  end

  context 'when the current user is not an enrolled student' do
    it 'returns not_eligible' do
      create(:tag, course:, tag: "#{slug}_opted_in")
      instructor = create(:user, username: 'NotAStudent')
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(instructor)
      post :opt_in, params: { experiment_slug: slug, course_id: course.id }
      expect(response).to have_http_status(422)
    end
  end
end
