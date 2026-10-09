# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/experiments/opt_in_experiment"

describe Experiments::StudentOptOutController, type: :controller do
  render_views

  let(:slug) { Fall2026ResearchExperiment::SLUG }
  let(:experiment) { Fall2026ResearchExperiment.new }
  let(:admin) { create(:admin) }
  let(:student) { create(:user, username: 'Some Student') }

  def enroll(course)
    create(:courses_user, user: student, course:, role: CoursesUsers::Roles::STUDENT_ROLE)
  end

  let(:participating_course) do
    create(:course, slug: 'School/Participating_(Fall_2026)', start: Date.new(2026, 9, 1),
                    end: Date.new(2026, 12, 15)).tap do |course|
      Tag.create!(course:, key: experiment.tag_key, tag: experiment.opted_in_tag)
    end
  end
  let(:eligible_course) do
    create(:course, slug: 'School/Eligible_(Fall_2026)', start: Date.new(2026, 9, 1),
                    end: Date.new(2026, 12, 15))
  end
  let(:other_term_course) do
    create(:course, slug: 'School/Other_(Spring_2026)', start: Date.new(2026, 1, 15),
                    end: Date.new(2026, 5, 1))
  end
  let!(:opted_in_enrollment) { enroll(participating_course) }
  let!(:undecided_enrollment) { enroll(eligible_course) }
  let!(:other_term_enrollment) { enroll(other_term_course) }
  let!(:opt_in_record) do
    ExperimentCoursesUser.create!(experiment_slug: slug, courses_user: opted_in_enrollment,
                                  status: :opted_in, userscript_installed_at: 1.day.ago)
  end

  before do
    allow(Features).to receive(:wiki_ed?).and_return(true)
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin)
  end

  describe 'GET #show' do
    it 'lists the student\'s enrollments covered by the experiment' do
      get :show, params: { experiment_slug: slug, username: 'Some_Student' }
      expect(response).to have_http_status(200)
      expect(assigns(:participations)).to eq(opted_in_enrollment => opt_in_record,
                                             undecided_enrollment => nil)
    end

    it 'leaves the user unassigned for an unknown username' do
      get :show, params: { experiment_slug: slug, username: 'Nobody' }
      expect(assigns(:user)).to be_nil
    end

    it 'is admin-only' do
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(student)
      get :show, params: { experiment_slug: slug }
      expect(response).to have_http_status(401)
    end

    it 'raises a routing error for an unknown experiment' do
      expect { get :show, params: { experiment_slug: 'not_a_thing' } }
        .to raise_error(ActionController::RoutingError)
    end
  end

  describe 'POST #opt_out' do
    it 'opts the student out of every covered course, including unanswered ones' do
      post :opt_out, params: { experiment_slug: slug, username: 'Some Student' }
      expect(opt_in_record.reload.opted_out?).to be true
      expect(experiment.participation(undecided_enrollment).opted_out?).to be true
      expect(experiment.participation(other_term_enrollment)).to be_nil
      expect(response).to redirect_to("/experiments/#{slug}/student_opt_out?username=Some+Student")
    end

    it 'leaves the student\'s records for other experiments alone' do
      other_record = ExperimentCoursesUser.create!(experiment_slug: 'another_experiment',
                                                   courses_user: opted_in_enrollment,
                                                   status: :opted_in)
      post :opt_out, params: { experiment_slug: slug, username: 'Some Student' }
      expect(other_record.reload.opted_in?).to be true
    end

    it 'flashes an error for an unknown username' do
      post :opt_out, params: { experiment_slug: slug, username: 'Nobody' }
      expect(flash[:error]).to be_present
      expect(response).to redirect_to("/experiments/#{slug}/student_opt_out")
    end
  end
end
