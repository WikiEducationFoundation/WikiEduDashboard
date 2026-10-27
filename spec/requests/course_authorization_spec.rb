# frozen_string_literal: true

require 'rails_helper'

describe 'Course authorization', type: :request do
  let(:instructor) { create(:user, username: 'OwnInstructor') }
  let(:outsider) { create(:user, username: 'Outsider') }
  let(:admin) { create(:admin) }
  let(:own_course) { create(:course, slug: 'Own_School/Own_Course_(term)') }
  let(:other_course) { create(:course, slug: 'Other_School/Other_Course_(term)') }
  let(:campaign) { Campaign.first }

  before do
    stub_wiki_validation
    create(:courses_user, course: own_course, user: instructor,
                          role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
  end

  # require_permissions used to check params[:id] before the route's own
  # :slug or :course_id, so ?id=<own course> passed for another course.
  describe 'naming an editable course in a query param' do
    before { login_as instructor }

    it 'does not open mass enrollment for another course' do
      get "/mass_enrollment/#{other_course.slug}", params: { id: own_course.slug }
      expect(response.status).to eq(401)
    end

    it 'does not open assignment progress for another course' do
      get "/courses/#{other_course.slug}/assignment_progress.json", params: { id: own_course.slug }
      expect(response.status).to eq(401)
    end

    it 'does not open another course\'s timeline for editing' do
      post "/courses/#{other_course.slug}/timeline",
           params: { id: own_course.slug, weeks: [] }, as: :json
      expect(response.status).to eq(401)
    end
  end

  describe 'adding a course to a campaign' do
    let(:path) { "/courses/#{own_course.slug}/campaign" }
    let(:params) { { campaign: { title: campaign.title } } }

    it 'refuses a logged-out visitor' do
      post path, params:, as: :json
      expect(response.status).to eq(401)
      expect(own_course.campaigns).to be_empty
    end

    context 'on Wiki Ed' do
      it 'refuses the course\'s own instructor' do
        login_as instructor
        post path, params:, as: :json
        expect(response.status).to eq(401)
        expect(own_course.campaigns).to be_empty
      end
    end

    context 'on P&E' do
      before { allow(Features).to receive(:wiki_ed?).and_return(false) }

      it 'lets the course\'s instructor add it' do
        login_as instructor
        post path, params:, as: :json
        expect(own_course.reload.campaigns).to include(campaign)
      end

      it 'refuses a user who can\'t edit the course' do
        login_as outsider
        post path, params:, as: :json
        expect(response.status).to eq(401)
        expect(own_course.campaigns).to be_empty
      end
    end
  end

  describe 'tagging a course' do
    let(:path) { "/courses/#{own_course.slug}/tag" }
    let(:params) { { tag: { tag: 'no_clone' } } }

    it 'refuses a logged-out visitor' do
      post path, params:, as: :json
      expect(response.status).to eq(401)
      expect(own_course.tags).to be_empty
    end

    it 'refuses a non-admin, even the course\'s instructor' do
      login_as instructor
      post path, params:, as: :json
      expect(response.status).to eq(401)
      expect(own_course.tags).to be_empty
    end

    it 'lets an admin add a tag' do
      login_as admin
      post path, params:, as: :json
      expect(own_course.reload.tags.pluck(:tag)).to eq(['no_clone'])
    end
  end

  describe 'editing a copied course before its setup is finished' do
    let(:copier) { create(:user, username: 'Copier') }
    let(:copied_course) do
      create(:course, slug: 'Copied_School/Copied_Course_(term)', cloned_status: 3,
                      flags: { copied_by_user_id: copier.id })
    end
    let(:path) { "/courses/#{copied_course.slug}" }
    let(:params) { { course: { title: 'Changed' } } }

    before { allow(UpdateCourseWorker).to receive(:schedule_edits) }

    it 'refuses a logged-out visitor' do
      put path, params:, as: :json
      expect(response.status).to eq(401)
      expect(copied_course.reload.title).not_to eq('Changed')
    end

    it 'refuses a signed-in user who didn\'t make the copy' do
      login_as outsider
      put path, params:, as: :json
      expect(response.status).to eq(401)
      expect(copied_course.reload.title).not_to eq('Changed')
    end

    it 'lets the user who made the copy finish it' do
      login_as copier
      put path, params:, as: :json
      expect(copied_course.reload.title).to eq('Changed')
    end

    it 'refuses a logged-out visitor deleting it' do
      delete path, as: :json
      expect(response.status).to eq(401)
      expect(Course.exists?(copied_course.id)).to be true
    end
  end
  describe 'deleting an approved course on Wiki Ed' do
    let(:approved_course) { create(:course, slug: 'Approved/Approved_course_(term)') }

    before do
      approved_course.campaigns << Campaign.first
      create(:courses_user, course: approved_course, user: instructor,
                            role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    end

    it 'is refused to the course\'s instructor' do
      expect(DeleteCourseWorker).not_to receive(:schedule_deletion)
      login_as instructor
      delete "/courses/#{approved_course.slug}.json"
      expect(response.status).to eq(401)
    end

    it 'is allowed for an admin' do
      expect(DeleteCourseWorker).to receive(:schedule_deletion)
      login_as admin
      delete "/courses/#{approved_course.slug}.json"
    end

    it 'is allowed for the instructor before approval' do
      approved_course.campaigns.clear
      expect(DeleteCourseWorker).to receive(:schedule_deletion)
      login_as instructor
      delete "/courses/#{approved_course.slug}.json"
    end
  end

  # courses#update and #create accepted every setting from any course editor,
  # including ones the UI shows only to admins.
  describe 'course settings an instructor sends on update' do
    let(:path) { "/courses/#{own_course.slug}" }

    before do
      allow(UpdateCourseWorker).to receive(:schedule_edits)
      login_as instructor
    end

    it 'ignores admin-only settings' do
      put path, params: { course: { withdrawn: true, declined: true, no_sandboxes: true,
                                    subject: 'Changed', flags: { max_group_size: 9 },
                                    last_reviewed: { username: 'X', timestamp: '2026' } } },
                as: :json
      own_course.reload
      expect(own_course.withdrawn).to be false
      expect(own_course.subject).not_to eq('Changed')
      expect(own_course.flags.values_at(:declined, :no_sandboxes, :max_group_size,
                                        'last_reviewed')).to all(be_nil)
    end

    it 'saves the settings instructors can change alongside them' do
      put path, params: { course: { description: 'Changed', withdrawn: true } }, as: :json
      expect(own_course.reload.description).to eq('Changed')
    end

    it 'lets the instructor submit the course but not unsubmit it' do
      allow(AnnounceCourseWorker).to receive(:schedule_announcement)
      put path, params: { course: { submitted: true } }, as: :json
      expect(own_course.reload.submitted).to be true
      login_as instructor # each JSON request gets a fresh session
      put path, params: { course: { submitted: false } }, as: :json
      expect(own_course.reload.submitted).to be true
    end

    it 'lets the instructor finish setting up a clone, and nothing else' do
      own_course.update!(cloned_status: Course::ClonedStatus::PENDING)
      put path, params: { course: { cloned_status: 0 } }, as: :json
      expect(own_course.reload.cloned_status).to eq(Course::ClonedStatus::PENDING)
      login_as instructor
      put path, params: { course: { cloned_status: Course::ClonedStatus::COMPLETED } }, as: :json
      expect(own_course.reload.cloned_status).to eq(Course::ClonedStatus::COMPLETED)
    end

    context 'on Wiki Ed' do
      it 'ignores type, privacy and the other rename-level settings' do
        put path, params: { course: { type: 'Editathon', private: true,
                                      disable_student_emails: true } }, as: :json
        own_course.reload
        expect(own_course.type).to eq('ClassroomProgramCourse')
        expect(own_course.private).to be false
        expect(own_course.disable_student_emails?).to be false
      end

      it 'leaves the edit settings as they were' do
        own_course.update!(flags: { 'edit_settings' => { 'assignment_edits_enabled' => false } })
        put path, params: { course: { assignment_edits_enabled: true } }, as: :json
        expect(own_course.reload.edit_settings).to eq('assignment_edits_enabled' => false)
      end

      it 'lets an admin change type and privacy' do
        login_as admin
        put path, params: { course: { type: 'Editathon', private: true } }, as: :json
        expect(Course.find(own_course.id).type).to eq('Editathon')
        expect(Course.find(own_course.id).private).to be true
      end
    end

    context 'on P&E' do
      before { allow(Features).to receive(:wiki_ed?).and_return(false) }

      it 'lets the instructor change type and privacy' do
        put path, params: { course: { type: 'Editathon', private: true } }, as: :json
        expect(Course.find(own_course.id).type).to eq('Editathon')
        expect(Course.find(own_course.id).private).to be true
      end

      it 'ignores a type the type selector doesn\'t offer' do
        own_course.update!(type: 'BasicCourse')
        put path, params: { course: { type: 'FellowsCohort' } }, as: :json
        expect(Course.find(own_course.id).type).to eq('BasicCourse')
      end
    end
  end

  describe 'course settings sent when creating a course' do
    let(:params) do
      { course: { school: 'New School', title: 'New Course', term: 'Fall', start: '2026-01-05',
                  end: '2026-05-20', subject: 'History', type: 'Editathon', private: true,
                  withdrawn: true, submitted: true } }
    end

    before { login_as outsider }

    context 'on Wiki Ed' do
      it 'ignores type, privacy and admin-only settings' do
        post '/courses', params:, as: :json
        course = Course.last
        expect(course.type).to eq(Features.default_course_type)
        expect([course.private, course.withdrawn]).to eq([false, false])
        expect(course.subject).to eq('History')
      end
    end

    context 'on P&E' do
      before { allow(Features).to receive(:wiki_ed?).and_return(false) }

      it 'keeps type and privacy but ignores withdrawn' do
        post '/courses', params:, as: :json
        course = Course.last
        expect([course.type, course.private, course.withdrawn]).to eq(['Editathon', true, false])
      end
    end
  end
end
