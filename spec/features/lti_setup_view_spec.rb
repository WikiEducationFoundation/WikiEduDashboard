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

  context 'with approved, current and future instructor-role courses' do
    before do
      campaign = create(:campaign)
      active = create(:course, slug: 'School/Active_Course_(2026)',
                               school: 'Demo U', title: 'Active Course', term: '2026',
                               start: 1.week.ago, end: 2.months.from_now)
      future = create(:course, slug: 'School/Upcoming_Course_(2026)',
                               school: 'Demo U', title: 'Upcoming Course', term: '2026',
                               start: 1.month.from_now, end: 4.months.from_now)
      [active, future].each do |c|
        CoursesUsers.create!(user: instructor, course: c,
                             role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
        create(:campaigns_course, campaign_id: campaign.id, course_id: c.id)
      end
    end

    it 'shows a course picker with the instructor\'s current and upcoming courses' do
      login_as(instructor)
      visit '/lti?ltik=ltik-abc'

      expect(page).to have_content('Set up the Wiki Education Dashboard')
      expect(page).to have_select('course_slug')
      # Options are labelled with the readable course title but submit the slug.
      expect(page).to have_css("#course_slug option[value='School/Active_Course_(2026)']",
                               text: 'Demo U - Active Course (2026)')
      expect(page).to have_css("#course_slug option[value='School/Upcoming_Course_(2026)']",
                               text: 'Demo U - Upcoming Course (2026)')
      expect(page).to have_content('One column for all trainings')
      expect(page).to have_link('Create a course on the Dashboard', href: '/')
    end
  end

  context 'with no approved, current or future instructor-role courses' do
    it 'hides the link form and elevates the create-new path' do
      login_as(instructor)
      visit '/lti?ltik=ltik-abc'

      within('.container.narrow') do
        expect(page).to have_no_select('course_slug')
        expect(page).to have_content('only available after your course has been approved')
        expect(page).to have_link('My Dashboard', href: '/')
      end
    end
  end
end
