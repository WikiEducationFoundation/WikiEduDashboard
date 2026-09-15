# frozen_string_literal: true

require 'rails_helper'

# An LTI 1.1 launch in the browser. Canvas posts these to our own endpoint,
# which redirects to /lti with a token we signed; this spec starts from that
# token rather than re-posting a signed launch, which
# LtiLegacyLaunchesController's request spec covers. Inside the Canvas iframe
# there is no Dashboard session, so both views here render from the launch
# identity alone, as they would in Canvas.
describe 'LTI 1.1 legacy launch', type: :feature, js: true do
  let(:instructor) { create(:user, username: 'Inst') }
  let(:student) { create(:user, username: 'Stu') }
  let(:course) do
    create(:course, slug: 'School/Legacy_Course_(2026)', title: 'Legacy Course',
                    start: 1.week.ago, end: 2.months.from_now)
  end
  let!(:binding) do
    LtiCourseBinding.create!(course:, lms_id: 'platform-x', lms_family: 'canvas',
                             lms_context_id: 'canvas-77', lms_resource_link_id: 'rl-legacy',
                             lms_context_title: 'Demo Canvas Course', lti_version: '1.2.0')
  end
  let(:role) { 'Instructor' }

  def idtoken
    {
      'ltiVersion' => '1.2.0',
      'user' => { 'id' => 'legacy-user-1', 'roles' => [role] },
      'platform' => { 'guid' => 'platform-x', 'productFamilyCode' => 'canvas' },
      'launch' => { 'context' => { 'id' => 'canvas-77', 'title' => 'Demo Canvas Course' },
                    'resourceLink' => { 'id' => 'rl-legacy' },
                    'presentation' => {
                      'returnUrl' => 'https://canvas.example.edu/courses/77/return'
                    } },
      'services' => { 'outcomes' => { 'available' => false } }
    }
  end

  def launch_path
    "/lti?ltik=#{CGI.escape(LtiLegacyLaunchToken.encode(idtoken))}"
  end

  before do
    allow(Features).to receive_messages(canvas_integration?: true, wiki_ed?: true,
                                        lti_legacy_launches?: true)
    allow(LtiRosterSyncWorker).to receive(:perform_async)
  end

  describe 'an instructor opening the linked course' do
    before do
      LtiContext.create!(user: instructor, lti_course_binding: binding,
                         user_lti_id: 'legacy-user-1', lms_id: 'platform-x',
                         roles: [role], linked_at: 1.day.ago)
      LtiContext.create!(user: student, lti_course_binding: binding,
                         user_lti_id: 'legacy-stu', lms_id: 'platform-x',
                         roles: ['Learner'], linked_at: 1.hour.ago)
    end

    it 'sees the launch-only status view: the link, the connected count, no sync machinery' do
      visit launch_path

      expect(page).to have_link('Legacy Course', href: "/courses/#{course.slug}")
      expect(page).to have_css('dt', text: I18n.t('lms_integration.connected_accounts'))
      expect(page).to have_css('dd', text: '1')
      expect(page).to have_no_content(I18n.t('lms_integration.roster_students'))
      expect(page).to have_no_content(I18n.t('lti.status.roster_sync_label'))
      expect(page).to have_no_button(I18n.t('lti.status.sync_grades'))
      expect(page).to have_no_content(I18n.t('lti.status.import_next_step.header'))
      expect(LtiRosterSyncWorker).not_to have_received(:perform_async)
    end
  end

  describe 'an enrolled student opening the linked course' do
    let(:role) { 'Learner' }

    before do
      LtiContext.create!(user: student, lti_course_binding: binding,
                         user_lti_id: 'legacy-user-1', lms_id: 'platform-x',
                         roles: [role], linked_at: 1.day.ago)
      CoursesUsers.create!(user: student, course:, role: CoursesUsers::Roles::STUDENT_ROLE)
    end

    it 'sees their progress overview in place, acting as their connected account' do
      visit launch_path

      expect(page).to have_link('Legacy Course', href: "/courses/#{course.slug}")
      expect(page).to have_content(I18n.t('lti.identity.signed_in_as', username: 'Stu'))
      expect(page).to have_no_content(I18n.t('lti.iframe_landing.button'))
    end
  end
end
