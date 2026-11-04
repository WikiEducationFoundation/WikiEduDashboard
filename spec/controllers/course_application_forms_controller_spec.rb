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
    it 'offers to add every question group not used in a survey' do
      base_group
      theme_group
      get path
      expect(response.body).to include('Base questions', 'Theme questions')
      expect(response.body).not_to include('Survey-only questions')
    end

    it 'lists the groups on the form in order, and does not offer them again' do
      CourseApplicationForm.create!(course:, question_group_ids: [theme_group.id, base_group.id])
      create(:question_group, name: 'Spare questions')
      get path
      page = Nokogiri::HTML(response.body)
      expect(page.css('[data-question-group-list] .course-application-form__group-name')
                 .map(&:text)).to eq(['Theme questions', 'Base questions'])
      expect(page.css('[data-question-group-add-select] option').map(&:text))
        .to eq(['', 'Spare questions'])
    end

    it 'labels its fields' do
      get path
      expect(response.body).to include('for="course_application_form_open"',
                                       'id="course_application_form_open"',
                                       'for="course_application_form_intro"',
                                       'id="course_application_form_intro"',
                                       'for="course_application_form_acceptance_email"',
                                       'id="course_application_form_acceptance_email"')
    end

    it 'links to creating a question group when none can be offered' do
      get path
      expect(response.body).to include(I18n.t('question_groups.none'),
                                       '/surveys/rapidfire/question_groups/new')
    end

    it 'says who the acceptance email comes from' do
      get path
      expect(response.body).to include("Sender: dashboard@#{ENV['dashboard_url']}")
    end

    it 'creates nothing just by being viewed' do
      get path
      expect(CourseApplicationForm.count).to eq(0)
    end
  end

  describe 'PATCH' do
    # As the page submits them: a leading blank id, then the list in order.
    def submit(ids:, add: '', open: '0', intro: 'Welcome', acceptance_email: 'See you Tuesday')
      patch path, params: { course_application_form: {
        open:, intro:, acceptance_email:,
        question_group_ids: [''] + ids.map(&:to_s), add_question_group_id: add.to_s
      } }
    end

    it 'saves the form, asking the groups in list order' do
      submit(open: '1', ids: [base_group.id, theme_group.id])
      expect(response).to redirect_to(path)

      form = course.reload.course_application_form
      expect(form).to be_open
      expect(form.intro).to eq('Welcome')
      expect(form.acceptance_email).to eq('See you Tuesday')
      expect(form.question_group_ids).to eq([base_group.id, theme_group.id])
    end

    it 'reorders the groups on a later save' do
      submit(ids: [base_group.id, theme_group.id])
      submit(ids: [theme_group.id, base_group.id])
      expect(course.reload.course_application_form.question_group_ids)
        .to eq([theme_group.id, base_group.id])
    end

    it 'adds the picked group to the end, as when JavaScript is off' do
      submit(ids: [base_group.id], add: theme_group.id)
      expect(course.reload.course_application_form.question_group_ids)
        .to eq([base_group.id, theme_group.id])
    end

    it 'removes every group when the list comes back empty' do
      submit(ids: [base_group.id])
      submit(ids: [])
      expect(course.reload.course_application_form.question_group_ids).to eq([])
    end

    it 'refuses to open a form with no question groups, saving nothing' do
      submit(open: '1', ids: [])
      expect(response).to have_http_status(:unprocessable_content)
      expect(CourseApplicationForm.count).to eq(0)
    end

    it 'refuses a group used in a survey' do
      submit(ids: [survey_group.id])
      expect(response).to have_http_status(:unprocessable_content)
      expect(CourseApplicationForm.count).to eq(0)
    end
  end
end
