# frozen_string_literal: true

require 'rails_helper'

describe 'LTI instructor setup view', type: :feature, js: true do
  let(:instructor) { create(:user, username: 'Inst', email: 'inst@example.edu') }

  before do
    allow(Features).to receive_messages(canvas_integration?: true, wiki_ed?: true)
    # Stub the LTIAAS idtoken fetch so /lti can build an LtiSession without
    # a real LTIAAS round-trip. Instructor role + minimal launch context.
    stub_request(:get, %r{wikiedu-test.ltiaas.com/api/idtoken})
      .to_return(status: 200, body: idtoken_body, headers: { 'Content-Type' => 'application/json' })
    ENV['LTIAAS_DOMAIN'] = 'wikiedu-test.ltiaas.com'
    ENV['LTIAAS_API_KEY'] = 'api-key'
    allow(LtiRosterSyncWorker).to receive(:perform_async)
  end

  def idtoken_body
    {
      user: { id: 'lti-inst-1', name: 'Inst', email: 'inst@example.edu',
              roles: ['http://purl.imsglobal.org/vocab/lis/v2/membership#Instructor'] },
      platform: { id: 'platform-x', productFamilyCode: 'canvas' },
      launch: {
        context: { id: 'canvas-77', title: 'Demo Canvas Course' },
        resourceLink: { id: 'rl-99' }
      },
      services: { serviceKey: 'svc-key', namesAndRoles: {}, assignmentAndGrades: {} }
    }.to_json
  end

  context 'with current and future instructor-role courses' do
    before do
      active = create(:course, slug: 'School/Active_Course_(2026)',
                               title: 'Wikipedia Writing 101',
                               start: 1.week.ago, end: 2.months.from_now)
      future = create(:course, slug: 'School/Upcoming_Course_(2026)',
                               title: 'Spring Editathon',
                               start: 1.month.from_now, end: 4.months.from_now)
      [active, future].each do |c|
        CoursesUsers.create!(user: instructor, course: c,
                             role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
      end
    end

    it 'shows a course picker with the instructor\'s current and upcoming courses' do
      login_as(instructor)
      visit '/lti?ltik=ltik-abc'

      expect(page).to have_content('Set up the Wiki Education Dashboard')
      expect(page).to have_select('course_slug')
      expect(page).to have_select('course_slug', options: ['',
                                                           'Wikipedia Writing 101',
                                                           'Spring Editathon'])
      expect(page).to have_content('One column for all trainings')
    end
  end

  context 'with no current or future instructor-role courses' do
    it 'hides the link form and elevates the create-new path' do
      login_as(instructor)
      visit '/lti?ltik=ltik-abc'

      expect(page).to have_no_select('course_slug')
      expect(page).to have_content('any active Wiki Education courses to link to yet')
      expect(page).to have_link('Create a Wiki Education course')
    end
  end
end
