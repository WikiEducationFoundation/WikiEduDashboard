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

  describe 'which page it is' do
    it '404s on the Programs & Events Dashboard' do
      allow(Features).to receive(:wiki_ed?).and_return(false)
      get path
      expect(response).to have_http_status(:not_found)
    end

    it '404s for a course type that does not take applications' do
      get "/courses/#{create(:course, slug: 'School/Classroom_(2027)').slug}/apply"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'GET' do
    context 'when nobody is signed in' do
      let(:viewer) { nil }

      it 'shows the intro and asks the visitor to log in, without the questions' do
        get path
        expect(response.body).to include('A six-week workshop.',
                                         I18n.t('course_applications.log_in_to_apply'))
        expect(response.body).not_to include('Describe your research background')
      end
    end

    it 'shows a signed-in user the questions' do
      get path
      expect(response.body).to include('Describe your research background')
    end

    it 'says applications are closed when the form is not open' do
      form.update!(open: false)
      get path
      expect(response.body).to include(I18n.t('course_applications.closed'))
      expect(response.body).not_to include('Describe your research background')
    end

    it 'says applications are closed once the course has ended' do
      course.update!(end: 1.day.ago)
      get path
      expect(response.body).to include(I18n.t('course_applications.closed'))
    end

    it 'says applications are closed for a course with no form' do
      form.destroy
      get path
      expect(response.body).to include(I18n.t('course_applications.closed'))
    end

    # Decisions are not shown on the page, only that the person applied.
    it 'confirms an existing application, whatever its status, even once closed' do
      CourseApplication.create!(course:, user:, status: :declined)
      form.update!(open: false)
      get path
      expect(response.body).to include(I18n.t('course_applications.submitted'))
      expect(response.body).not_to include('Describe your research background')
    end

    it 'sends a student already in the course to the course page' do
      create(:courses_user, course:, user:, role: CoursesUsers::Roles::STUDENT_ROLE)
      get path
      expect(response).to redirect_to("/courses/#{course.slug}")
    end
  end

  describe 'POST' do
    it 'saves the application and returns to the page, which confirms it' do
      post path, params: { answers: }
      expect(response).to redirect_to(path)
      expect(CourseApplication.find_by(course:, user:)).to be_submitted
      follow_redirect!
      expect(response.body).to include(I18n.t('course_applications.submitted'))
    end

    it 're-shows the form with the answers kept when one is missing' do
      other = create(:q_short, question_group:, question_text: 'Current title')
      post path, params: { answers: }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include(I18n.t('course_applications.invalid'),
                                       'I study elections.', "answer_#{other.id}_errors")
      expect(CourseApplication.count).to eq(0)
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
