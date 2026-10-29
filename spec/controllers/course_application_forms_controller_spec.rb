# frozen_string_literal: true

require 'rails_helper'

describe CourseApplicationFormsController, type: :request do
  let(:course) { create(:fellows_cohort) }
  let(:path) { "/courses/#{course.slug}/application_form" }
  let(:admin) { create(:admin) }
  let(:base_group) { create(:question_group, name: 'Base questions') }
  let(:theme_group) { create(:question_group, name: 'Theme questions') }
  let(:survey_group) { create(:question_group, name: 'Survey-only questions') }

  before do
    create(:survey).rapidfire_question_groups << survey_group
    login_as admin
  end

  describe 'who may reach it' do
    it 'refuses a non-admin' do
      login_as create(:user, username: 'NotAnAdmin')
      get path
      expect(response).to have_http_status(:unauthorized)
    end

    it '404s on the Programs & Events Dashboard' do
      allow(Features).to receive(:wiki_ed?).and_return(false)
      get path
      expect(response).to have_http_status(:not_found)
    end

    it '404s for a course type that does not take applications' do
      get "/courses/#{create(:course, slug: 'School/Classroom_(2026)').slug}/application_form"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'GET' do
    it 'offers every question group not used in a survey' do
      base_group
      theme_group
      get path
      expect(response.body).to include('Base questions', 'Theme questions')
      expect(response.body).not_to include('Survey-only questions')
    end

    it 'labels its fields' do
      get path
      expect(response.body).to include('for="course_application_form_open"',
                                       'id="course_application_form_open"',
                                       'for="course_application_form_intro"',
                                       'id="course_application_form_intro"')
    end

    it 'creates nothing just by being viewed' do
      get path
      expect(CourseApplicationForm.count).to eq(0)
    end
  end

  describe 'PATCH' do
    def submit(positions:, open: '0', intro: 'Welcome')
      patch path, params: { course_application_form: { open:, intro:, positions: } }
    end

    it 'saves the form, asking the groups in position order and skipping blanks' do
      unused = create(:question_group, name: 'Unused')
      submit(open: '1', positions: { base_group.id => '1', theme_group.id => '2', unused.id => '' })
      expect(response).to redirect_to(path)

      form = course.reload.course_application_form
      expect(form).to be_open
      expect(form.intro).to eq('Welcome')
      expect(form.question_group_ids).to eq([base_group.id, theme_group.id])
    end

    it 'reorders the groups on a later save' do
      submit(positions: { base_group.id => '1', theme_group.id => '2' })
      submit(positions: { base_group.id => '2', theme_group.id => '1' })
      expect(course.reload.course_application_form.question_group_ids)
        .to eq([theme_group.id, base_group.id])
    end

    it 'refuses to open a form with no question groups, saving nothing' do
      submit(open: '1', positions: { base_group.id => '' })
      expect(response).to have_http_status(:unprocessable_content)
      expect(CourseApplicationForm.count).to eq(0)
    end

    it 'refuses a group used in a survey' do
      submit(positions: { survey_group.id => '1' })
      expect(response).to have_http_status(:unprocessable_content)
      expect(CourseApplicationForm.count).to eq(0)
    end
  end
end
