# frozen_string_literal: true

require 'rails_helper'

describe UsersController, type: :request do
  describe '#enroll' do
    subject { response.status }

    let(:slug_params) { 'Wikipedia_Fellows/Basket-weaving_fellows_(summer_2018)' }
    let(:course) { create(:course, slug: slug_params) }
    let(:request_params) do
      { course_id: course.slug, passcode: course.passcode, titleterm: 'foobar' }
    end
    let(:user) { create(:user) }
    let(:admin) { create(:admin) }
    let(:super_admin) { create(:super_admin) }
    let(:another_user) { create(:user, username: 'StudentUser') }

    before do
      allow_any_instance_of(WikiCourseEdits).to receive(:update_course)
      allow_any_instance_of(WikiCourseEdits).to receive(:remove_assignment)
      allow_any_instance_of(WikiCourseEdits).to receive(:update_assignments)
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
      course.campaigns << Campaign.first
    end

    # Users who are not part of the course enroll via SelfEnrollmentController
    context 'POST, when the user is not part of the course' do
      let(:post_params) do
        { id: course.slug,
          user: { user_id: user.id, role: CoursesUsers::Roles::STUDENT_ROLE } }
      end

      before do
        post "/courses/#{course.slug}/user", params: post_params
      end

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
            user: { user_id: user.id, role: CoursesUsers::Roles::STUDENT_ROLE } }
        end

        before do
          post "/courses/#{course.slug}/user", params: post_params
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
            user: { username: another_user.username, role: CoursesUsers::Roles::STUDENT_ROLE } }
        end

        before do
          expect_any_instance_of(WikiCourseEdits).to receive(:enroll_in_course)
          post "/courses/#{course.slug}/user", params: post_params
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
      let(:post_params) do
        { id: course.slug,
          user: { user_id: admin.id, role: CoursesUsers::Roles::STUDENT_ROLE }.as_json }
      end

      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin)
        stub_oauth_edit
        stub_raw_action
        post "/courses/#{course.slug}/user", params: post_params
      end

      it 'returns a 200' do
        expect(subject).to eq(200)
      end

      it 'enrolls the user' do
        expect(CoursesUsers.where(role: CoursesUsers::Roles::STUDENT_ROLE).count).to eq(1)
      end
    end

    context 'POST with Wiki Ed staff role, when the user is an admin' do
      let(:post_params) do
        { id: course.slug,
          user: { user_id: admin.id, role: CoursesUsers::Roles::WIKI_ED_STAFF_ROLE } }
      end

      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin)
        post "/courses/#{course.slug}/user", params: post_params
      end

      it 'returns a 200' do
        expect(subject).to eq(200)
      end

      it 'enrolls the user' do
        expect(CoursesUsers.where(role: CoursesUsers::Roles::WIKI_ED_STAFF_ROLE).count).to eq(1)
      end
    end

    context 'POST with instructor role, when the user is is allowed' do
      let(:staff) { create(:user, username: 'Staffer', email: 'staffer@wikiedu.org') }
      let(:post_params) do
        { id: course.slug,
          user: { user_id: admin.id, role: CoursesUsers::Roles::INSTRUCTOR_ROLE } }
      end

      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin)
        SpecialUsers.set_user('classroom_program_manager', staff.username)
        allow(NewInstructorEnrollmentMailer).to receive(:send_staff_alert).and_call_original
        post "/courses/#{course.slug}/user", params: post_params
      end

      it 'returns a 200' do
        expect(subject).to eq(200)
      end

      it 'sends an email alert' do
        expect(CoursesUsers.where(role: CoursesUsers::Roles::INSTRUCTOR_ROLE).count).to eq(1)
        expect(NewInstructorEnrollmentMailer).to have_received(:send_staff_alert)
      end
    end

    context 'DELETE' do
      let(:delete_params) do
        { id: course.slug,
          user: { user_id: user.id, role: CoursesUsers::Roles::STUDENT_ROLE } }
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
      end

      it 'destroys the courses user' do
        delete "/courses/#{course.slug}/user", params: delete_params
        expect(CoursesUsers.count).to eq(0)
      end

      it 'succeeds' do
        delete "/courses/#{course.slug}/user", params: delete_params
        expect(subject).to eq(200)
      end

      context 'when the course is controlled by event_sync' do
        before do
          course.flags[:event_sync] = '1234'
          course.save
        end

        it 'returns unauthorized' do
          delete "/courses/#{course.slug}/user", params: delete_params
          expect(subject).to eq(401)
        end
      end

      context 'when the user is already removed' do
        before do
          allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin)
        end

        it 'returns the list of users' do
          delete "/courses/#{course.slug}/user", params: delete_params # remove the user
          delete "/courses/#{course.slug}/user", params: delete_params # attempt to re-remove
          expect(JSON.parse(response.body).dig('course', 'users')).to be_a(Array)
          expect(subject).to eq(200)
        end
      end
    end
  end

  describe '#index' do
    context 'when user is NOT admin' do
      let(:user) { create(:user) }

      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
      end

      it 'does not authorize' do
        get '/users'
        expect(response.body).to include('Only administrators may do that.')
      end
    end

    context 'when user IS admin' do
      let(:admin) { create(:admin, email: 'admin@email.com') }

      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin)
      end

      let!(:instructor) do
        create(:user, email: 'instructor@school.edu',
                      real_name: 'Sare Goss', username: 'saregoss',
                      permissions: User::Permissions::INSTRUCTOR)
      end

      let(:search_user) { create(:user, email: 'findme@example.com', real_name: 'Joe Bloggs') }

      it 'lists instructors by default' do
        get '/users'
        expect(response.body).to include(instructor.username)
        expect(response.body).to include(instructor.real_name)
        expect(response.body).to include(instructor.email)
        expect(response.body).not_to include(admin.email)
      end

      it 'accepts email param and return associated user' do
        get '/users', params: { email: search_user.email }
        expect(response.body).to include(search_user.email)
      end

      it 'accepts real name param and return associated user' do
        get '/users', params: { real_name: search_user.real_name }
        expect(response.body).to include(search_user.real_name)
      end
    end
  end
end
