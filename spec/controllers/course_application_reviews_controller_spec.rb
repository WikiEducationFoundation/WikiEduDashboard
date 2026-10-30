# frozen_string_literal: true

require 'rails_helper'

describe CourseApplicationReviewsController, type: :request do
  let(:course) do
    create(:fellows_cohort, slug: 'Wiki_Education/Elections_workshop_(2027)',
                            end: 2.months.from_now)
  end
  let(:base_path) { "/courses/#{course.slug}/applications" }
  let(:admin) { create(:admin) }
  let(:viewer) { admin }
  let(:applicant) { create(:user, username: 'Historian', onboarded: true) }
  let(:question_group) { create(:question_group, name: 'Base') }
  let!(:question) do
    create(:q_long, question_group:, question_text: 'Describe your research background')
  end
  let!(:application) do
    CourseApplicationForm.create!(course:, open: true, question_group_ids: [question_group.id])
    SubmitCourseApplication.new(course:, user: applicant, answers: {
                                  question.id.to_s => { answer_text: '<b>I study elections.</b>' }
                                }).application
  end
  let(:application_path) { "#{base_path}/#{application.id}" }

  before do
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(viewer)
  end

  describe 'access' do
    it '404s on the Programs & Events Dashboard' do
      allow(Features).to receive(:wiki_ed?).and_return(false)
      get base_path
      expect(response).to have_http_status(:not_found)
    end

    context 'when the viewer is not an admin' do
      let(:viewer) { applicant }

      it 'refuses every action' do
        get application_path
        expect(response).to have_http_status(:unauthorized)
        post "#{application_path}/accept"
        expect(response).to have_http_status(:unauthorized)
        expect(application.reload).to be_submitted
      end
    end

    it '404s for an application to another course' do
      other = create(:fellows_cohort, slug: 'Wiki_Education/Other_(2027)')
      get "/courses/#{other.slug}/applications/#{application.id}"
      expect(response).to have_http_status(:not_found)
    end
  end

  it 'lists the applications' do
    get base_path
    expect(response.body).to include('Historian', application_path)
  end

  it 'shows an application with its answers, escaped' do
    get application_path
    expect(response.body).to include('Describe your research background',
                                     '&lt;b&gt;I study elections.&lt;/b&gt;')
  end

  it 'exports the applications as CSV' do
    get "#{base_path}.csv"
    expect(response.media_type).to eq('text/csv')
    expect(response.body).to include('Historian', '<b>I study elections.</b>')
  end

  it 'saves staff notes' do
    patch application_path, params: { course_application: { staff_notes: 'Strong fit' } }
    expect(response).to redirect_to(application_path)
    expect(application.reload.staff_notes).to eq('Strong fit')
  end

  describe 'accepting' do
    it 'offers no accept button before the course is approved' do
      get application_path
      expect(response.body).to include(I18n.t('courses.join_failure_details.not_yet_approved'))
      expect(response.body).not_to include("#{application_path}/accept")
    end

    it 'refuses, with the reason, before the course is approved' do
      post "#{application_path}/accept"
      expect(response).to redirect_to(application_path)
      expect(flash[:error]).to eq(I18n.t('courses.join_failure_details.not_yet_approved'))
      expect(application.reload).to be_submitted
    end

    it 'accepts and enrolls once the course is approved' do
      course.campaigns << create(:campaign)
      post "#{application_path}/accept"
      expect(response).to redirect_to(application_path)
      expect(application.reload).to be_accepted
      expect(course.students).to include(applicant)
    end
  end

  it 'declines' do
    post "#{application_path}/decline"
    expect(response).to redirect_to(application_path)
    expect(application.reload).to be_declined
  end
end
