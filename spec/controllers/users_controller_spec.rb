# frozen_string_literal: true
require 'rails_helper'

describe UsersController do
  describe '#enroll' do
    let(:course) { create(:course) }
    let(:request_params) do
      { course_id: course.slug, passcode: course.passcode, titleterm: 'foobar' }
    end
    let(:user) { create(:user) }
    let(:admin) { create(:admin) }
    let(:another_user) { create(:user, username: 'StudentUser') }

    before do
      allow_any_instance_of(WikiCourseEdits).to receive(:update_course)
      allow_any_instance_of(WikiCourseEdits).to receive(:remove_assignment)
      allow_any_instance_of(WikiCourseEdits).to receive(:update_assignments)
      allow(controller).to receive(:current_user).and_return(user)
      course.campaigns << Campaign.first
    end

    subject { response.status }

    # Users who are not part of the course enroll via SelfEnrollmentController
    context 'POST, when the user is not part of the course' do
      let(:post_params) do
        { id: course.slug,
          user: { user_id: user.id, role: CoursesUsers::Roles::STUDENT_ROLE }.as_json }
      end
      before { post 'enroll', params: post_params }
      it 'does not create a CoursesUsers' do
        expect(CoursesUsers.count).to eq(0)
      end
      it 'returns a 401' do
        expect(subject).to eq(401)
      end
    end

    context 'POST with student role, when enroller is instructor' do
      before do
        create(:courses_user, user_id: user.id,
                              course_id: course.id,
                              role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
      end

      context 'and the enrollee is the same user' do
        let(:post_params) do
          { id: course.slug,
            user: { user_id: user.id, role: CoursesUsers::Roles::STUDENT_ROLE }.as_json }
        end
        before do
          post 'enroll', params: post_params
        end
        it 'returns a 404' do
          expect(subject).to eq(404)
        end
        it 'does not enroll the user' do
          expect(CoursesUsers.where(role: CoursesUsers::Roles::STUDENT_ROLE).count).to eq(0)
        end
      end

      context 'and the enrollee is not in the course yet' do
        let(:post_params) do
          { id: course.slug,
            user: { username: another_user.username, role: CoursesUsers::Roles::STUDENT_ROLE }.as_json }
        end
        before do
          expect_any_instance_of(WikiCourseEdits).to receive(:enroll_in_course)
          post 'enroll', params: post_params
        end
        it 'returns a 200' do
          expect(subject).to eq(200)
        end
        it 'enrolls the user' do
          expect(CoursesUsers.where(role: CoursesUsers::Roles::STUDENT_ROLE).count).to eq(1)
        end
      end
    end

    context 'POST with student role, when the user is an admin' do
      before do
        allow(controller).to receive(:current_user).and_return(admin)
        stub_oauth_edit
      end

      let(:post_params) do
        { id: course.slug,
          user: { user_id: admin.id, role: CoursesUsers::Roles::STUDENT_ROLE }.as_json }
      end
      before do
        post 'enroll', params: post_params
      end
      it 'returns a 200' do
        expect(subject).to eq(200)
      end
      it 'enrolls the user' do
        expect(CoursesUsers.where(role: CoursesUsers::Roles::STUDENT_ROLE).count).to eq(1)
      end
    end

    context 'POST with nonstudent role, when the user is an admin' do
      before do
        allow(controller).to receive(:current_user).and_return(admin)
      end

      let(:post_params) do
        { id: course.slug,
          user: { user_id: admin.id, role: CoursesUsers::Roles::WIKI_ED_STAFF_ROLE }.as_json }
      end
      before do
        post 'enroll', params: post_params
      end
      it 'returns a 200' do
        expect(subject).to eq(200)
      end
      it 'enrolls the user' do
        expect(CoursesUsers.where(role: CoursesUsers::Roles::WIKI_ED_STAFF_ROLE).count).to eq(1)
      end
    end

    context 'DELETE' do
      let(:delete_params) do
        { id: course.slug,
          user: { user_id: user.id, role: CoursesUsers::Roles::STUDENT_ROLE }.as_json }
      end
      before do
        create(:courses_user, user_id: user.id,
                              course_id: course.id,
                              role: CoursesUsers::Roles::STUDENT_ROLE)
        article = create(:article)
        create(:assignment,
               course_id: course.id,
               user_id: user.id,
               article_id: article.id)
        delete 'enroll', params: delete_params
      end
      it 'destroys the courses user' do
        expect(CoursesUsers.count).to eq(0)
      end
      it 'succeeds' do
        expect(subject).to eq(200)
      end
    end
  end

  describe '#update_locale' do
    let(:user) { create(:user, locale: 'fr') }

    before do
      allow(controller).to receive(:current_user).and_return(user)
    end

    it 'returns a 422 if locale is invalid' do
      put 'update_locale', params: { locale: 'bad-locale' }
      expect(response.status).to eq(422)
      expect(user.locale).to eq('fr')
    end

    it 'updates user locale and returns a 200 if locale is valid' do
      put 'update_locale', params: { locale: 'es' }
      expect(response.status).to eq(200)
      expect(user.locale).to eq('es')
    end
  end

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
end
