# frozen_string_literal: true
# == Schema Information
#
# Table name: users
#
#  id                  :integer          not null, primary key
#  username            :string(255)
#  created_at          :datetime
#  updated_at          :datetime
#  trained             :boolean          default(FALSE)
#  global_id           :integer
#  remember_created_at :datetime
#  remember_token      :string(255)
#  wiki_token          :string(255)
#  wiki_secret         :string(255)
#  permissions         :integer          default(0)
#  real_name           :string(255)
#  email               :string(255)
#  onboarded           :boolean          default(FALSE)
#  greeted             :boolean          default(FALSE)
#  greeter             :boolean          default(FALSE)
#  locale              :string(255)
#  chat_password       :string(255)
#  chat_id             :string(255)
#  registered_at       :datetime
#  first_login         :datetime
#

require 'rails_helper'

describe User do
  describe 'user creation' do
    it 'creates User objects' do
      ragesock = build(:user)
      ragesauce = build(:admin)
      expect(ragesock.username).to eq('Ragesock')
      expect(ragesauce.admin?).to be true
    end
  end

  describe 'user deletion' do
    it 'destroys the User and associated CampaignsUsers and CoursesUsers' do
      user = create(:user)
      course = create(:course)
      create(:courses_user, user_id: user.id, course_id: course.id)
      create(:campaigns_user, user_id: user.id)
      expect(CoursesUsers.count).to eq(1)
      expect(CampaignsUsers.count).to eq(1)
      user.destroy
      expect(CoursesUsers.count).to eq(0)
      expect(CampaignsUsers.count).to eq(0)
    end
  end

  describe '#course_roles' do
    it 'returns an array of roles a user has in a course' do
      course = create(:course)
      user = create(:user)
      create(:courses_user,
             course_id: course.id,
             user_id: user.id,
             role: CoursesUsers::Roles::STUDENT_ROLE)

      create(:courses_user,
             course_id: course.id,
             user_id: user.id,
             role: CoursesUsers::Roles::INSTRUCTOR_ROLE)

      roles = user.course_roles(course)
      expect(roles).to contain_exactly(1, 0)
    end

    it 'returns an empty array when the user has no roles in the course' do
      course = create(:course)
      user = create(:user)
      roles = user.course_roles(course)
      expect(roles).to be_empty
    end
  end

  describe '#highest_role' do
    it 'returns the highest role a user has in a course - multiple roles' do
      course = create(:course)
      user = create(:user)
      create(:courses_user,
             course_id: course.id,
             user_id: user.id,
             role: CoursesUsers::Roles::INSTRUCTOR_ROLE)

      create(:courses_user,
             course_id: course.id,
             user_id: user.id,
             role: CoursesUsers::Roles::CAMPUS_VOLUNTEER_ROLE)
      highest_role = user.highest_role(course)
      expect(highest_role).to be(2)
    end

    it 'returns the highest role a user has in a course' do
      course = create(:course)
      user = create(:user)
      create(:courses_user,
             course_id: course.id,
             user_id: user.id,
             role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
      highest_role = user.highest_role(course)
      expect(highest_role).to be(1)
    end

    it 'returns visitor role when user has no role in the course' do
      course = create(:course)
      user = create(:user)

      highest_role = user.highest_role(course)
      expect(highest_role).to be(-1)
    end
  end

  describe '#can_edit?' do
    it 'returns true for users with non-student roles' do
      course = create(:course)
      user = create(:user)
      create(:courses_user,
             course_id: course.id,
             user_id: user.id,
             role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
      permission = user.can_edit?(course)
      expect(permission).to be true
    end

    it 'returns false for students and visitors' do
      course = create(:course)
      user = create(:user)
      # User is not associated with course.
      permission = user.can_edit?(course)
      expect(permission).to be false

      # Now user is a student.
      create(:courses_user,
             course_id: course.id,
             user_id: user.id,
             role: CoursesUsers::Roles::STUDENT_ROLE)
      permission = user.can_edit?(course)
      expect(permission).to be false
    end

    it 'returns true for users with multiple roles, including an editing role' do
      course = create(:course)
      user = create(:user)
      # User is an instructor
      create(:courses_user,
             course_id: course.id,
             user_id: user.id,
             role: CoursesUsers::Roles::INSTRUCTOR_ROLE)

      # User is also a campus volunteer
      create(:courses_user,
             course_id: course.id,
             user_id: user.id,
             role: CoursesUsers::Roles::CAMPUS_VOLUNTEER_ROLE)

      permission = user.can_edit?(course)
      expect(permission).to be true
    end
  end

  describe '#nonvisitor' do
    it 'returns false when the user has only visitor role' do
      course = create(:course)
      user = create(:user)
      permission = user.nonvisitor?(course)
      expect(permission).to be false
    end

    it 'returns true when the user has one non-visitor role' do
      course = create(:course)
      user = create(:user)
      create(:courses_user,
             course_id: course.id,
               user_id: user.id,
               role: CoursesUsers::Roles::STUDENT_ROLE)
      permission = user.nonvisitor?(course)
      expect(permission).to be true
    end

    it 'returns true for users with multiple roles, including a visitor role' do
      # User is a visitor
      course = create(:course)
      user = create(:user)

      # User is also a campus volunteer
      create(:courses_user,
             course_id: course.id,
             user_id: user.id,
             role: CoursesUsers::Roles::CAMPUS_VOLUNTEER_ROLE)

      permission = user.nonvisitor?(course)
      expect(permission).to be true
    end
  end

  describe '#can_see_real_names?' do
    it 'returns true when the user has an instructor role' do
      course = create(:course)
      user = create(:user)
      create(:courses_user,
             course_id: course.id,
             user_id: user.id,
             role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
      permission = user.can_see_real_names?(course)
      expect(permission).to be true
    end

    it 'returns true when the user has a staff role' do
      course = create(:course)
      user = create(:user)
      create(:courses_user,
             course_id: course.id,
              user_id: user.id,
              role: CoursesUsers::Roles::WIKI_ED_STAFF_ROLE)
      permission = user.can_see_real_names?(course)
      expect(permission).to be true
    end

    it 'returns true for users with multiple roles, including a real name role' do
      # User is a visitor
      course = create(:course)
      user = create(:user)
      permission = user.can_see_real_names?(course)
      expect(permission).to be false

      # Now user is an instructor
      create(:courses_user,
             course_id: course.id,
             user_id: user.id,
             role: CoursesUsers::Roles::INSTRUCTOR_ROLE)

      permission = user.can_see_real_names?(course)
      expect(permission).to be true
    end

    it 'returns false when the user has no real name role' do
      course = create(:course)
      user = create(:user)
      create(:courses_user,
             course_id: course.id,
              user_id: user.id,
              role: CoursesUsers::Roles::STUDENT_ROLE)
      permission = user.can_see_real_names?(course)
      expect(permission).to be false
    end

    it 'returns false when the user has multiple roles and no real name role' do
      course = create(:course)
      user = create(:user)
      create(:courses_user,
             course_id: course.id,
              user_id: user.id,
              role: CoursesUsers::Roles::STUDENT_ROLE)

      create(:courses_user,
             course_id: course.id,
               user_id: user.id,
               role: CoursesUsers::Roles::CAMPUS_VOLUNTEER_ROLE)
      permission = user.can_see_real_names?(course)
      expect(permission).to be false
    end
  end

  describe 'email validation' do
    context 'when email is valid' do
      it 'saves the email' do
        user = described_class.new(username: 'foo', email: 'me@foo.com')
        user.save
        expect(user.email).to eq('me@foo.com')
      end
    end

    context 'when email is not valid' do
      it 'sets email to nil and saves' do
        user = described_class.new(username: 'foo', email: 'me@foo')
        user.save
        expect(user.email).to be_nil
      end
    end
  end

  describe '#returning_instructor?' do
    let(:user) { create(:user) }
    let(:course) { create(:course) }
    let(:subject) { user.returning_instructor? }
    let(:add_user_as_instructor) do
      create(:courses_user, user_id: user.id, course_id: course.id,
                            role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    end
    let(:add_user_as_student) do
      create(:courses_user, user_id: user.id, course_id: course.id,
                            role: CoursesUsers::Roles::STUDENT_ROLE)
    end
    let(:approve_course) do
      create(:campaigns_course, campaign_id: Campaign.first.id, course_id: course.id)
    end

    context 'when user has no courses' do
      it 'returns false' do
        expect(subject).to eq(false)
      end
    end

    context 'when user has just created their first course' do
      before do
        add_user_as_instructor
      end

      it 'returns false' do
        expect(subject).to eq(false)
      end
    end

    context 'when user is a student in an approved course' do
      before do
        approve_course
        add_user_as_student
      end

      it 'returns false' do
        expect(subject).to eq(false)
      end
    end

    context 'when user is an instructor in an approved course' do
      before do
        approve_course
        add_user_as_instructor
      end

      it 'returns true' do
        expect(subject).to eq(true)
      end
    end
  end

  describe '#profile_image' do
    let(:user) { create(:user) }

    before do
      create(:user_profile, user:, image_file_link: 'https://example.com/cat.png')
    end

    it 'returns a URL when the user has an image set' do
      expect(user.profile_image).to eq('https://example.com/cat.png')
    end
  end

  describe '#search' do
    let(:search_user) { create(:user, email: 'findme@example.com', real_name: 'Find Me') }
    let(:similar_search_user) { create(:user, username: 'similar', email: 'find@example.com') }

    it 'returns user(s) with given email address' do
      result = described_class.search_by_email(search_user.email)

      expect(result).to eq([search_user])
    end

    it 'returns user(s) with given full name' do
      result = described_class.search_by_real_name(search_user.real_name)
      expect(result).to eq([search_user])
    end

    it 'returns user(s) without full email' do
      # The word 'find' is present in both emails.
      result = described_class.search_by_email('find')

      expect(result).to eq([search_user, similar_search_user])
    end
  end
end
