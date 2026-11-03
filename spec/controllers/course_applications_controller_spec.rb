# frozen_string_literal: true

require 'rails_helper'

describe CourseApplicationsController, type: :request do
  let(:course) do
    create(:fellows_cohort, slug: 'Wiki_Education/Elections_workshop_(2027)',
                            end: 2.months.from_now)
  end
  let(:path) { "/courses/#{course.slug}/apply" }
  let(:user) { create(:user, onboarded: true) }
  let(:viewer) { user }
  let(:question_group) { create(:question_group, name: 'Base') }
  let!(:question) do
    create(:q_long, question_group:, question_text: 'Describe your research background')
  end
  let!(:form) do
    CourseApplicationForm.create!(course:, open: true, intro: 'A six-week workshop.',
                                  question_group_ids: [question_group.id])
  end
  let(:answers) { { question.id.to_s => { answer_text: 'I study elections.' } } }

  before do
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(viewer)
  end

  let(:form_path) { "/courses/#{course.slug}/apply/form" }

  describe 'which page it is' do
    it '404s on the Programs & Events Dashboard' do
      allow(Features).to receive(:wiki_ed?).and_return(false)
      get form_path
      expect(response).to have_http_status(:not_found)
    end

    it '404s for a course type that does not take applications' do
      get "/courses/#{create(:course, slug: 'School/Classroom_(2027)').slug}/apply/form"
      expect(response).to have_http_status(:not_found)
    end
  end

  # The apply link itself is the course page; the form page only serves
  # someone who can apply, and sends everyone else back to the card there.
  describe 'GET the form' do
    it 'shows a signed-in user the intro and the questions' do
      get form_path
      expect(response.body).to include('A six-week workshop.', 'Describe your research background')
    end

    context 'when nobody is signed in' do
      let(:viewer) { nil }

      it 'returns to the apply card' do
        get form_path
        expect(response).to redirect_to(path)
      end
    end

    it 'returns to the apply card when the form is not open' do
      form.update!(open: false)
      get form_path
      expect(response).to redirect_to(path)
    end

    it 'returns to the apply card once the course has ended' do
      course.update!(end: 1.day.ago)
      get form_path
      expect(response).to redirect_to(path)
    end

    it 'returns to the apply card for a course with no form' do
      form.destroy
      get form_path
      expect(response).to redirect_to(path)
    end

    it 'returns to the apply card once the user has applied' do
      CourseApplication.create!(course:, user:)
      get form_path
      expect(response).to redirect_to(path)
    end

    it 'sends a student already in the course to the course page' do
      create(:courses_user, course:, user:, role: CoursesUsers::Roles::STUDENT_ROLE)
      get form_path
      expect(response).to redirect_to("/courses/#{course.slug}")
    end
  end

  describe 'the apply card, from the course JSON' do
    def application_json
      get "/courses/#{course.slug}/course.json"
      response.parsed_body.dig('course', 'application')
    end

    it 'gives an open form, its intro, and the form link' do
      expect(application_json).to include('has_form' => true, 'open' => true, 'applied' => false,
                                          'form_url' => form_path)
      expect(application_json['intro_html']).to include('A six-week workshop.')
    end

    it 'says when the form is closed' do
      form.update!(open: false)
      expect(application_json).to include('open' => false)
    end

    # Decisions are not shown, only that the person applied.
    it 'says the user has applied, whatever the decision' do
      CourseApplication.create!(course:, user:, status: :declined)
      expect(application_json).to include('applied' => true)
    end

    it 'is left out for a course type that does not take applications' do
      classroom = create(:course, slug: 'School/Classroom_(2027)')
      get "/courses/#{classroom.slug}/course.json"
      expect(response.parsed_body['course']).not_to have_key('application')
    end
  end

  describe 'POST' do
    it 'saves the application and returns to the apply card' do
      post path, params: { answers: }
      expect(response).to redirect_to(path)
      expect(CourseApplication.find_by(course:, user:)).to be_submitted
    end

    it 're-shows the form with the answers kept when one is missing' do
      other = create(:q_short, question_group:, question_text: 'Current title')
      post path, params: { answers: }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include(I18n.t('error.form_errors'),
                                       'I study elections.', "answer_#{other.id}_errors",
                                       I18n.t('application.field_required'))
      expect(response.body).not_to include("can't be blank", 'can&#39;t be blank')
      expect(CourseApplication.count).to eq(0)
    end

    it 'gives a length error in its own words' do
      question.update!(validation_rules: question.rules.merge(minimum: '50'))
      post path, params: { answers: }
      expect(response.body).to include('too short')
      expect(response.body).not_to include(I18n.t('application.field_required'))
    end

    context 'when nobody is signed in' do
      let(:viewer) { nil }

      it 'refuses' do
        post path, params: { answers: }
        expect(response).to have_http_status(:unauthorized)
        expect(CourseApplication.count).to eq(0)
      end
    end

    it 'saves nothing when the form is closed' do
      form.update!(open: false)
      post path, params: { answers: }
      expect(response).to redirect_to(path)
      expect(CourseApplication.count).to eq(0)
    end

    it 'saves nothing more for someone who has already applied' do
      CourseApplication.create!(course:, user:)
      post path, params: { answers: }
      expect(response).to redirect_to(path)
      expect(CourseApplication.count).to eq(1)
      expect(Rapidfire::Answer.count).to eq(0)
    end
  end
end
