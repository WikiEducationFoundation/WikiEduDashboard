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
      let(:unauthorised_user) { create(:user) }
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
      it 'displays instructor cumulative statistics' do
        get :show, params: { username: user.username }
        expect(response).to render_template(partial: '_instructor_cumulative_stats')
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
      it 'displays student cumulative statistics' do
        get :show, params: { username: user.username }
        expect(response).to render_template(partial: '_student_cumulative_stats')
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
      it 'does not display student cumulative statistics' do
        get :show, params: { username: user.username }
        expect(response).not_to render_template(partial: '_student_cumulative_stats')
      end
      it 'does not display instructor cumulative statistics' do
        get :show, params: { username: user.username }
        expect(response).not_to render_template(partial: '_instructor_cumulative_stats')
      end
    end
  end
  describe '#update' do
    context 'when user has a profile' do
      let(:user) { create(:user) }
      let(:profile) { create(:user_profile, user_id: user.id, bio: 'Howdy') }
      it "updates the bio" do
        post :update, params: { username: user.username, user_profile: { id: profile.id, user_id: profile.user_id, bio: profile.bio} }
        expect(user.user_profile.bio).to eq 'Howdy'
      end
    end
  end
end
