# frozen_string_literal: true

require 'rails_helper'

describe LtiIntegrationsController, type: :request do
  let(:admin) { create(:admin) }
  let(:user) { create(:user) }
  let(:learner_role) { ['http://purl.imsglobal.org/vocab/lis/v2/membership#Learner'] }
  let(:course) { create(:course, title: 'Bound course', slug: 'School/Bound_course') }
  let(:instructor) { create(:user, username: 'BoundInstructor') }

  let!(:binding) do
    LtiCourseBinding.create!(
      course:, lms_id: 'platform-x', lms_family: 'canvas',
      lms_context_id: 'canvas-77', lms_resource_link_id: 'rl-99',
      lms_context_title: 'WRIT 2010', lms_platform_url: 'https://school.instructure.com'
    )
  end

  before do
    create(:courses_user, course:, user: instructor,
                          role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    # One connected learner and one who hasn't connected a Wikipedia account.
    LtiContext.create!(lti_course_binding: binding, user: create(:user, username: 'Connected'),
                       user_lti_id: 'lti-1', lms_id: 'platform-x', roles: learner_role)
    LtiContext.create!(lti_course_binding: binding, user_lti_id: 'lti-2', lms_id: 'platform-x',
                       roles: learner_role)
  end

  context 'as an admin' do
    before { login_as admin }

    let(:row) { Capybara.string(response.body).find('tr', text: 'WRIT 2010') }

    it 'lists a bound course with its Canvas course and instance' do
      get '/lti_integrations'
      expect(row).to have_link('Bound course', href: "/courses/#{course.slug}")
      expect(row).to have_css('td.lms-instance', text: 'school.instructure.com')
      expect(row).to have_css('td.instructor', text: 'BoundInstructor')
    end

    it 'shows connected students and roster size' do
      get '/lti_integrations'
      expect(row).to have_css('td.lti-version', text: '1.3')
      expect(row).to have_css('td.connected-students', text: '1')
      expect(row).to have_css('td.roster', text: '2')
    end

    it 'does not report a roster for an LTI 1.1 install' do
      binding.update!(lti_version: '1.2.0')
      get '/lti_integrations'
      expect(row).to have_css('td.lti-version', text: '1.1')
      expect(row).to have_css('td.roster', text: '—')
    end

    it 'lists a Canvas course whose setup has not picked a Dashboard course yet' do
      LtiCourseBinding.create!(lms_id: 'platform-x', lms_family: 'canvas',
                               lms_context_id: 'canvas-88', lms_resource_link_id: 'rl-100',
                               lms_context_title: 'HIST 3000')
      get '/lti_integrations'
      unbound = Capybara.string(response.body).find('tr', text: 'HIST 3000')
      expect(unbound).to have_css('td.dashboard-course', text: '—')
    end
  end

  context 'as a non-admin' do
    before { login_as user }

    it 'is not authorized' do
      get '/lti_integrations'
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
