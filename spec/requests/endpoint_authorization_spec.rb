# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/importers/user_importer"

# Authorization checks for endpoints that had none, or the wrong one. Each
# section covers a refusal and the use the UI makes of the endpoint.
describe 'Endpoint authorization', type: :request do
  let(:user) { create(:user, username: 'SignedInUser') }
  let(:admin) { create(:admin) }

  describe 'deleting a profile image' do
    let(:owner) { create(:user, username: 'ImageOwner') }

    before { create(:user_profile, user_id: owner.id, image_file_link: 'https://example.org/me.png') }

    it 'is refused to another user' do
      login_as user
      delete "/users/#{owner.username}/profile_image"
      expect(owner.user_profile.reload.image_file_link).to be_present
    end

    it 'works for the profile owner' do
      login_as owner
      delete "/users/#{owner.username}/profile_image"
      expect(owner.user_profile.reload.image_file_link).to be_nil
    end
  end

  describe 'refreshing a campaign\'s cached stats' do
    let(:campaign) { create(:campaign, slug: 'stats_campaign') }
    let(:path) { "/campaigns/#{campaign.slug}/refresh" }

    it 'is refused to a signed-in user who is not an organizer' do
      expect(Rails.cache).not_to receive(:delete)
      login_as user
      get path
    end

    it 'works for an organizer' do
      create(:campaigns_user, campaign:, user:, role: CampaignsUsers::Roles::ORGANIZER_ROLE)
      expect(Rails.cache).to receive(:delete).with(campaign.course_sums_cache_key)
      expect(Rails.cache).to receive(:delete).with(campaign.articles_count_cache_key)
      login_as user
      get path
    end
  end

  describe 'disabling a campaign\'s account requests' do
    let(:campaign) { create(:campaign, slug: 'requests_campaign', register_accounts: true) }
    let(:path) { "/requested_accounts_campaigns/#{campaign.slug}/disable_account_requests" }

    it 'is refused to a logged-out visitor' do
      put path
      expect(campaign.reload.register_accounts).to be true
    end

    it 'is refused to a signed-in user who is not an admin' do
      login_as user
      put path
      expect(campaign.reload.register_accounts).to be true
    end

    it 'works for an admin' do
      login_as admin
      put path
      expect(campaign.reload.register_accounts).to be false
    end
  end

  describe 'removing a course from a campaign via the campaign page' do
    let(:course) { create(:course, slug: 'Shared/Shared_course_(term)') }
    let(:own_campaign) { create(:campaign, title: 'Own', slug: 'own_campaign') }
    let(:other_campaign) { create(:campaign, title: 'Other', slug: 'other_campaign') }

    before do
      course.campaigns << own_campaign
      course.campaigns << other_campaign
      create(:campaigns_user, campaign: own_campaign, user:,
                              role: CampaignsUsers::Roles::ORGANIZER_ROLE)
      login_as user
    end

    def remove_from(campaign)
      delete "/courses/#{course.slug}.json/delete_from_campaign",
             params: { campaign_id: campaign.id, campaign_title: campaign.title,
                       campaign_slug: campaign.slug }
    end

    it 'is refused for a campaign the user does not organize' do
      remove_from(other_campaign)
      expect(response.status).to eq(401)
      expect(course.reload.campaigns).to include(other_campaign)
    end

    it 'works for the campaign the user organizes' do
      remove_from(own_campaign)
      expect(course.reload.campaigns).not_to include(own_campaign)
    end
  end

  describe 'filing an alert about a course' do
    let(:course) { create(:course, slug: 'Alert/Alert_course_(term)') }
    let(:staff) { create(:user, username: 'CourseStaff', email: 'staff@example.org') }
    let(:bystander) { create(:user, username: 'Bystander', email: 'other@example.org') }
    let(:params) do
      { alert_type: 'NeedHelpAlert', course_id: course.id, message: 'help', format: :json }
    end

    before do
      create(:courses_user, course:, user: staff, role: CoursesUsers::Roles::WIKI_ED_STAFF_ROLE)
    end

    it 'is refused to a signed-in user who is not in the course' do
      login_as user
      post '/alerts', params: params
      expect(response.status).to eq(401)
      expect(Alert.count).to eq(0)
    end

    context 'from a student in the course' do
      before do
        create(:courses_user, course:, user:, role: CoursesUsers::Roles::STUDENT_ROLE)
        login_as user
      end

      it 'goes to the course staff member the Get Help button names' do
        post '/alerts', params: params.merge(target_user_id: staff.id)
        expect(Alert.last.target_user).to eq(staff)
      end

      it 'ignores a target who is not the course\'s staff' do
        post '/alerts', params: params.merge(target_user_id: bystander.id)
        expect(Alert.last.target_user).not_to eq(bystander)
      end
    end

    it 'is open to anyone signed in when it names no course' do
      login_as user
      post '/alerts', params: params.except(:course_id)
      expect(NeedHelpAlert.count).to eq(1)
    end
  end

  describe 'recent uploads' do
    let(:private_course) { create(:course, slug: 'Hidden/Hidden_(term)', private: true) }
    let(:public_course) { create(:course, slug: 'Open/Open_(term)') }
    let(:hidden_student) { create(:user, username: 'HiddenStudent') }
    let(:open_student) { create(:user, username: 'OpenStudent') }

    before do
      create(:courses_user, course: private_course, user: hidden_student,
                            role: CoursesUsers::Roles::STUDENT_ROLE)
      create(:courses_user, course: public_course, user: open_student,
                            role: CoursesUsers::Roles::STUDENT_ROLE)
      create(:commons_upload, user: hidden_student, file_name: 'File:Hidden.jpg')
      create(:commons_upload, user: open_student, file_name: 'File:Open.jpg')
    end

    it 'lists only uploads by students of non-private courses' do
      get '/revision_analytics/recent_uploads.json'
      uploaders = JSON.parse(response.body)['uploads'].pluck('uploader')
      expect(uploaders).to eq(['OpenStudent'])
    end
  end

  describe 'training status' do
    let(:course) { create(:course, slug: 'Training/Training_course_(term)') }
    let(:stranger) { create(:user, username: 'Stranger') }

    before do
      create(:courses_user, course:, user:, role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
      login_as user
    end

    it 'is not shown to an instructor for a user outside the course' do
      get '/training_status.json', params: { course_id: course.id, user_id: stranger.id }
      expect(response.body).to eq('{}')
    end
  end

  describe 'training progress for a course' do
    let(:course) { create(:course, slug: 'Progress/Progress_course_(term)') }
    let(:classmate) { create(:user, username: 'Classmate') }

    before do
      create(:courses_user, course:, user:, role: CoursesUsers::Roles::STUDENT_ROLE)
      create(:courses_user, course:, user: classmate, role: CoursesUsers::Roles::STUDENT_ROLE)
      create(:block, week: create(:week, course:), training_module_ids: [1])
      login_as user
    end

    it 'returns no blocks, rather than the viewer\'s own progress, for a classmate' do
      get '/training_modules_users.json', params: { course_id: course.id, user_id: classmate.id }
      expect(JSON.parse(response.body)['blocks']).to eq([])
    end

    it 'returns the blocks for the viewer\'s own progress' do
      get '/training_modules_users.json', params: { course_id: course.id, user_id: user.id }
      expect(JSON.parse(response.body)['blocks'].count).to eq(1)
    end
  end

  describe 'verifying an exercise article from another course\'s timeline' do
    let(:other_course) { create(:course, slug: 'Other/Other_course_(term)') }
    let(:training_module) { TrainingModule.find_by(slug: 'update-a-biography-exercise') }
    let(:block) do
      create(:block, week: create(:week, course: other_course),
                     training_module_ids: [training_module.id])
    end

    before { TrainingModule.load_all }

    it 'is refused' do
      expect(VerifyExerciseArticle).not_to receive(:new)
      login_as user
      post '/training_modules_users/verify_exercise_article.json',
           params: { module_id: training_module.slug, block_id: block.id,
                     article_title: 'Selfie' }, as: :json
      expect(response.status).to eq(401)
    end
  end

  describe 'enrolling a username the dashboard has not seen' do
    let(:course) { create(:course, slug: 'Enroll/Enroll_course_(term)') }

    # Non-participants are already turned away by require_participating_user.
    it 'does not import the user for a student in the course' do
      create(:courses_user, course:, user:, role: CoursesUsers::Roles::STUDENT_ROLE)
      expect(UserImporter).not_to receive(:new_from_username)
      login_as user
      post "/courses/#{course.slug}/user",
           params: { user: { username: 'BrandNewUser', role: 0 } }, as: :json
      expect(response.status).to eq(401)
    end
  end
end
