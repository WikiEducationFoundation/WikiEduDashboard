# frozen_string_literal: true

require 'rails_helper'

describe TaggedCoursesController, type: :request do
  let(:admin) { create(:admin, email: 'admin@wiki.edu') }
  let(:tag_name) { 'test_tag' }
  let(:course) { create(:course) }
  let(:user) { create(:user, email: 'student@hello.edu') }

  before do
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin)
    create(:tag, course: course, tag: tag_name)
    create(:courses_user, course: course, user: user)
    create(:alert, course: course)
  end

  describe '#articles' do
    it 'renders a 200 and assigns the correct data' do
      get "/tagged_courses/#{tag_name}/articles?page=4"
      expect(response.status).to eq(200)
      expect(assigns(:tag)).to eq(tag_name)
      expect(assigns(:page)).to eq(4)
    end

    it 'initializes the CoursesPresenter with correct data' do
      get "/tagged_courses/#{tag_name}/articles?page=2"

      presenter = assigns(:presenter)
      expect(presenter).to be_a(CoursesPresenter)
      expect(presenter.current_user).to eq(admin)
      # Accessing instance variables directly since they aren't all attr_readers
      expect(presenter.instance_variable_get(:@tag)).to eq(tag_name)
      expect(presenter.instance_variable_get(:@page)).to eq(2)
      expect(presenter.instance_variable_get(:@courses_list)).to include(course)
    end

    it 'handles missing page parameters by defaulting to nil' do
      get "/tagged_courses/#{tag_name}/articles"
      expect(assigns(:page)).to be_nil
    end
  end

  describe '#programs' do
    it 'loads wiki experts and renders successfully' do
      expert = create(:user, username: 'expert_user')
      allow(SpecialUsers).to receive(:wikipedia_experts).and_return([expert])
      create(:courses_user, course: course, user: expert,
             role: CoursesUsers::Roles::WIKI_ED_STAFF_ROLE)

      get "/tagged_courses/#{tag_name}/programs"

      expect(response).to be_successful
      expect(assigns(:wiki_experts)).not_to be_empty
      expect(assigns(:wiki_experts).first.user).to eq(expert)
    end
  end

  describe '#stats' do
    it 'returns the stats in JSON format' do
      get "/tagged_courses/#{tag_name}.json"

      expect(response).to be_successful
      expect(response.content_type).to include('application/json')
    end
  end

  describe '#alerts' do
    it 'assigns alerts for the courses' do
      get "/tagged_courses/#{tag_name}/alerts.json"

      expect(response).to be_successful
      # Ensure alerts are correctly scoped to the courses in the tag
      expect(assigns(:alerts)).not_to be_empty
      expect(assigns(:alerts).first.course).to eq(course)
    end
  end
end
