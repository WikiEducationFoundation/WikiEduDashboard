# frozen_string_literal: true

require 'rails_helper'

describe Users::EnrollmentController, type: :request do
  let(:course) { create(:course, slug: 'School/Course_(term)') }
  let(:student) { create(:user, username: 'PlainStudent') }
  let(:instructor) { create(:user, username: 'CourseInstructor') }
  let(:admin) { create(:admin) }
  let(:staff) { create(:user, username: 'Staffer', email: 'staffer@wikiedu.org') }
  let(:target) { create(:user, username: 'NewFacilitator') }

  def enroll(role)
    post "/courses/#{course.slug}/user",
         params: { id: course.slug, user: { user_id: target.id, role: } }
  end

  def act_as(user)
    allow_any_instance_of(ApplicationController)
      .to receive(:current_user).and_return(user)
  end

  def instructor_record
    CoursesUsers.find_by(course:, user: target,
                         role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
  end

  before do
    allow_any_instance_of(WikiCourseEdits).to receive(:update_course)
    allow_any_instance_of(WikiCourseEdits).to receive(:update_assignments)
    allow_any_instance_of(WikiCourseEdits).to receive(:enroll_in_course)
    allow_any_instance_of(WikiCourseEdits).to receive(:remove_assignment)
    allow_any_instance_of(WikiApi).to receive(:get_page_content).and_return('content')
    course.campaigns << Campaign.first
    SpecialUsers.set_user('classroom_program_manager', staff.username)
    create(:courses_user, course:, user: student,
                          role: CoursesUsers::Roles::STUDENT_ROLE)
    create(:courses_user, course:, user: instructor,
                          role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
  end

  context 'when the requesting user is only a student in the course' do
    before { act_as(student) }

    it 'refuses to enroll another user as an instructor' do
      enroll(CoursesUsers::Roles::INSTRUCTOR_ROLE)
      expect(response.status).to eq(401)
    end

    it 'creates no instructor record' do
      enroll(CoursesUsers::Roles::INSTRUCTOR_ROLE)
      expect(instructor_record).to be_nil
    end

    it 'can still enroll another user as a student' do
      enroll(CoursesUsers::Roles::STUDENT_ROLE)
      expect(response.status).to eq(200)
    end

    # WIKI_ED_STAFF_ROLE is the other role in User::EDITING_ROLES, so granting
    # it confers the same can_edit? rights as the instructor role.
    it 'refuses to enroll another user in the staff role' do
      enroll(CoursesUsers::Roles::WIKI_ED_STAFF_ROLE)
      expect(response.status).to eq(401)
    end

    it 'creates no staff record' do
      enroll(CoursesUsers::Roles::WIKI_ED_STAFF_ROLE)
      expect(CoursesUsers.exists?(course:, user: target,
                                  role: CoursesUsers::Roles::WIKI_ED_STAFF_ROLE)).to be false
    end

    it 'refuses to remove a staff-role user from the course' do
      create(:courses_user, course:, user: target,
                            role: CoursesUsers::Roles::WIKI_ED_STAFF_ROLE)
      delete "/courses/#{course.slug}/user",
             params: { id: course.slug,
                       user: { user_id: target.id,
                               role: CoursesUsers::Roles::WIKI_ED_STAFF_ROLE } }
      expect(CoursesUsers.exists?(course:, user: target,
                                  role: CoursesUsers::Roles::WIKI_ED_STAFF_ROLE)).to be true
    end

    it 'refuses to remove an instructor from the course' do
      delete "/courses/#{course.slug}/user",
             params: { id: course.slug,
                       user: { user_id: instructor.id,
                               role: CoursesUsers::Roles::INSTRUCTOR_ROLE } }
      expect(CoursesUsers.exists?(course:, user: instructor,
                                  role: CoursesUsers::Roles::INSTRUCTOR_ROLE)).to be true
    end
  end

  context 'when the requesting user is an instructor in the course' do
    before { act_as(instructor) }

    # Adding a TA or co-instructor is a normal instructor action.
    it 'enrolls another user as an instructor' do
      enroll(CoursesUsers::Roles::INSTRUCTOR_ROLE)
      expect(response.status).to eq(200)
    end

    it 'creates the instructor record' do
      enroll(CoursesUsers::Roles::INSTRUCTOR_ROLE)
      expect(instructor_record).not_to be_nil
    end
  end

  context 'when the requesting user is an instructor and the role is staff' do
    before { act_as(instructor) }

    it 'enrolls another user in the staff role' do
      enroll(CoursesUsers::Roles::WIKI_ED_STAFF_ROLE)
      expect(response.status).to eq(200)
    end
  end

  context 'when the requesting user is an admin' do
    before { act_as(admin) }

    it 'enrolls another user as an instructor' do
      enroll(CoursesUsers::Roles::INSTRUCTOR_ROLE)
      expect(instructor_record).not_to be_nil
    end
  end
end
