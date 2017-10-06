# frozen_string_literal: true

require 'rails_helper'

describe UserProfilesController do
  describe '#show' do
    render_views

    context 'when user not found' do
      it 'redirects to the home page' do
        get :show, params: { username: 'non existing user' }
        expect(response.body).to redirect_to(root_path)
      end
    end

    context 'when the user is enrolled in a course' do
      let(:course) { create(:course) }
      let(:user) { create(:user) }
      let!(:courses_user) do
        create(:courses_user, course_id: course.id,
                              user_id: user.id)
      end
      it 'lists the course' do
        get :show, params: { username: user.username }
        expect(response.body).to have_content course.title
      end
    end

    context 'when current_user is same user' do
      let(:user) { create(:user, email: 'fake_email@gmail.com') }
      it 'shows the email id' do
        allow(controller).to receive(:current_user).and_return(user)
        get :show, params: { username: user.username }
        expect(response.body).to have_content user.email
      end
    end

    context 'when current_user is admin' do
      let(:user) { create(:user, email: 'fake_email@gmail.com') }
      let(:admin) { create(:admin) }
      it 'shows the email id' do
        allow(controller).to receive(:current_user).and_return(admin)
        get :show, params: { username: user.username }
        expect(response.body).to have_content user.email
      end
    end

    context 'when current_user is not the same user nor an admin' do
      let(:user) { create(:user, email: 'fake_email@gmail.com') }
      let(:unauthorised_user) { create(:user, username: 'unauthorized') }
      it 'does not shows the email id' do
        allow(controller).to receive(:current_user).and_return(unauthorised_user)
        get :show, params: { username: user.username }
        expect(response.body).not_to have_content user.email
      end
    end

    context 'when user is an instructor' do
      let(:course) { create(:course) }
      let(:user) { create(:user) }
      let!(:courses_user) do
        create(:courses_user, course_id: course.id,
                              user_id: user.id,
                              role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
      end
      it 'displays the profile navbar' do
        get :show, params: { username: user.username }
        expect(response).to render_template(partial: '_profile_nav')
      end
    end

    context 'when user is a student' do
      let(:course) { create(:course) }
      let(:user) { create(:user) }
      let!(:courses_user) do
        create(:courses_user, course_id: course.id,
                              user_id: user.id,
                              role: CoursesUsers::Roles::STUDENT_ROLE)
      end
      it 'displays the profile navbar' do
        get :show, params: { username: user.username }
        expect(response).to render_template(partial: '_profile_nav')
      end
    end

    context 'when user is neither a student nor an instructor' do
      let(:course) { create(:course) }
      let(:user) { create(:user) }
      let!(:courses_user) do
        create(:courses_user, course_id: course.id,
                              user_id: user.id,
                              role: CoursesUsers::Roles::ONLINE_VOLUNTEER_ROLE)
      end
      it 'does not display the profile navbar' do
        get :show, params: { username: user.username }
        expect(response).not_to render_template(partial: '_profile_nav')
      end
    end
  end
  describe '#update' do
    context 'user profile is of the current user' do
      let(:user) { create(:user) }
      let(:profile) { create(:user_profile, user_id: user.id) }
      before do
        allow(controller).to receive(:current_user).and_return(user)
      end
      it 'updates the bio' do
        post :update, params: { username: user.username, user_profile: { id: profile.id, user_id: profile.user_id, bio: 'Howdy' } }
        expect(user.user_profile.bio).to eq 'Howdy'
      end

      it 'updates the location' do
        post :update, params: { username: user.username, user_profile: { id: profile.id, user_id: profile.user_id, location: 'Seattle' } }
        expect(user.user_profile.location).to eq 'Seattle'
      end

      it 'updates the Institution' do
        post :update, params: { username: user.username, user_profile: { id: profile.id, user_id: profile.user_id, institution: 'Institution' } }
        expect(user.user_profile.institution).to eq 'Institution'
      end

      it 'updates the Image' do
        file = fixture_file_upload('wiki-logo.png', 'image/png')
        post :update, params: { username: user.username, user_profile: { id: profile.id, user_id: profile.user_id, image: file } }
        expect(response.status).to eq(302)
        expect(user.user_profile.image).not_to be_nil
      end
    end

    context 'user profile is not of the current user' do
      let(:user) { create(:user) }
      let(:profile) { create(:user_profile, user_id: user.id) }
      it 'doesn\'t update the bio' do
        post :update, params: { username: user.username, user_profile: { id: profile.id, user_id: profile.user_id, bio: 'Howdy' } }
        expect(user.user_profile.bio).not_to eq 'Howdy'
      end

      it ' doesn\'t update the location' do
        post :update, params: { username: user.username, user_profile: { id: profile.id, user_id: profile.user_id, location: 'Seattle' } }
        expect(user.user_profile.location).not_to eq 'Seattle'
      end

      it 'doesn\'t update the Institution' do
        post :update, params: { username: user.username, user_profile: { id: profile.id, user_id: profile.user_id, institution: 'Institution' } }
        expect(user.user_profile.institution).not_to eq 'Institution'
      end

      it 'doesn\'t update the Image' do
        file = fixture_file_upload('wiki-logo.png', 'image/png')
        post :update, params: { username: user.username, user_profile: { id: profile.id, user_id: profile.user_id, image: file } }
        expect(response.status).not_to eq(302)
      end
    end
  end
end
