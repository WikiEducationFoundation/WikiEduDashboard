# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/experiments/opt_in_experiment"

describe Experiments::InstructorOptInController, type: :controller do
  let(:slug) { Fall2026ResearchExperiment::SLUG }
  let(:experiment) { Fall2026ResearchExperiment.new }
  let(:instructor) { create(:user, username: 'Prof') }

  def create_eligible_course(title)
    create(:course, title:, slug: "School/#{title}_(Fall_2026)",
                    start: Date.new(2026, 9, 1), end: Date.new(2026, 12, 15))
  end

  def instruct(course)
    create(:courses_user, user: instructor, course:, role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
  end

  let!(:undecided_course) { create_eligible_course('Undecided').tap { |c| instruct(c) } }
  let!(:opted_out_course) do
    create_eligible_course('Opted_out').tap do |course|
      instruct(course)
      Tag.create!(course:, key: experiment.tag_key, tag: experiment.opted_out_tag)
    end
  end
  # Eligible, but this instructor's choice must not touch someone else's course.
  let!(:other_instructors_course) { create_eligible_course('Other') }

  before do
    allow(Features).to receive(:wiki_ed?).and_return(true)
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(instructor)
  end

  describe 'GET #show' do
    it 'assigns the eligible instructed courses with their current choices' do
      get :show, params: { experiment_slug: slug }
      expect(response).to have_http_status(200)
      expect(assigns(:courses)).to contain_exactly(undecided_course, opted_out_course)
      expect(assigns(:choices)[undecided_course]).to be_nil
      expect(assigns(:choices)[opted_out_course]).to eq(:opted_out)
    end

    it 'requires login' do
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(nil)
      get :show, params: { experiment_slug: slug }
      expect(response).to have_http_status(401)
    end

    it 'raises a routing error for an unknown experiment' do
      expect { get :show, params: { experiment_slug: 'not_a_thing' } }
        .to raise_error(ActionController::RoutingError)
    end
  end

  describe 'POST #opt_in' do
    it 'opts in every eligible instructed course, overriding an earlier opt-out' do
      post :opt_in, params: { experiment_slug: slug }
      expect(experiment.course_choice(undecided_course)).to eq(:opted_in)
      expect(experiment.course_choice(opted_out_course)).to eq(:opted_in)
      expect(experiment.course_participating?(opted_out_course)).to be true
      expect(experiment.course_choice(other_instructors_course)).to be_nil
    end

    it 'records only one tag per course, like the wizard' do
      post :opt_in, params: { experiment_slug: slug }
      expect(Tag.where(course: opted_out_course, key: experiment.tag_key).count).to eq(1)
    end

    it 'confirms and returns to the page' do
      post :opt_in, params: { experiment_slug: slug }
      expect(flash[:notice]).to eq(experiment.instructor_invitation_copy[:opted_in_flash])
      expect(response).to redirect_to("/experiments/#{slug}/instructor_optin")
    end
  end

  describe 'POST #opt_out' do
    it 'opts out every eligible instructed course' do
      post :opt_out, params: { experiment_slug: slug }
      expect(experiment.course_choice(undecided_course)).to eq(:opted_out)
      expect(experiment.course_choice(opted_out_course)).to eq(:opted_out)
      expect(flash[:notice]).to eq(experiment.instructor_invitation_copy[:opted_out_flash])
    end
  end

  context 'for a user with no eligible courses' do
    let(:student) { create(:user, username: 'NotAnInstructor') }

    before do
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(student)
    end

    it 'shows the page with no courses' do
      get :show, params: { experiment_slug: slug }
      expect(response).to have_http_status(200)
      expect(assigns(:courses)).to be_empty
    end

    it 'records nothing and shows no confirmation on a posted choice' do
      expect { post :opt_in, params: { experiment_slug: slug } }.not_to change(Tag, :count)
      expect(flash[:notice]).to be_nil
      expect(response).to redirect_to("/experiments/#{slug}/instructor_optin")
    end
  end
end
