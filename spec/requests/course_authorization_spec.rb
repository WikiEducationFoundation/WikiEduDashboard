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
end
