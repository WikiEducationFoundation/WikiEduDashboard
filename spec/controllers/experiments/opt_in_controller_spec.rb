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

  def stub_common_js(content)
    allow_any_instance_of(WikiApi).to receive(:get_page_content).and_return(content)
  end

  def opt_student_in
    ExperimentCoursesUser.create!(experiment_slug: slug, courses_user:, status: :opted_in)
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

    it 'reports no userscript step for a student who has not opted in' do
      create(:tag, course:, tag: "#{slug}_opted_in")
      get :show, params: { course_id: course.id }
      expect(response.parsed_body['userscript']).to be_nil
    end

    it 'reports the outstanding userscript step for an opted-in student' do
      create(:tag, course:, tag: "#{slug}_opted_in")
      opt_student_in
      stub_common_js ''
      get :show, params: { course_id: course.id }
      expect(response.parsed_body['userscript']['install_url']).to be_present
    end

    it 'clears the userscript step and records the install once the line is on-wiki' do
      create(:tag, course:, tag: "#{slug}_opted_in")
      record = opt_student_in
      stub_common_js "#{Fall2026ResearchExperiment.new.userscript_import_line}\n"
      get :show, params: { course_id: course.id }
      expect(response.parsed_body['userscript']).to be_nil
      expect(record.reload.userscript_installed_at).to be_present
    end

    it 'does not re-read the wiki once the install is recorded' do
      create(:tag, course:, tag: "#{slug}_opted_in")
      opt_student_in.update!(userscript_installed_at: Time.zone.now)
      expect_any_instance_of(WikiApi).not_to receive(:get_page_content)
      get :show, params: { course_id: course.id }
      expect(response.parsed_body['userscript']).to be_nil
    end
  end

  describe 'POST #opt_in' do
    before { create(:tag, course:, tag: "#{slug}_opted_in") }

    it 'records the opt-in' do
      stub_common_js ''
      post :opt_in, params: { experiment_slug: slug, course_id: course.id }
      record = ExperimentCoursesUser.find_by(courses_user:, experiment_slug: slug)
      expect(record.opted_in?).to be true
    end

    it 'returns the import line to paste and a link to the edit form' do
      stub_common_js ''
      post :opt_in, params: { experiment_slug: slug, course_id: course.id }
      userscript = response.parsed_body['userscript']
      expect(userscript['import_line']).to eq(Fall2026ResearchExperiment.new.userscript_import_line)
      expect(userscript['install_url']).to include('action=edit')
      expect(userscript['install_url']).not_to include('preload')
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
