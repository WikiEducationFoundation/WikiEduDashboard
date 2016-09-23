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
#

require "#{Rails.root}/lib/utils"

#= User model
class User < ActiveRecord::Base
  alias_attribute :wiki_id, :username

  validates :permissions, inclusion: { in: [0, 1, 2] }
  before_validation :ensure_valid_email

  #############
  # Constants #
  #############
  module Permissions
    NONE  = 0
    ADMIN = 1
    INSTRUCTOR = 2
  end

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :rememberable, :omniauthable, omniauth_providers: [:mediawiki, :mediawiki_signup]

  has_many :courses_users, class_name: CoursesUsers
  has_many :survey_notifications, through: :courses_users
  has_many :courses, -> { distinct }, through: :courses_users
  has_many :revisions, -> { where(system: false) }
  has_many :all_revisions, class_name: Revision
  has_many :articles, -> { distinct }, through: :revisions
  has_many :assignments
  has_many :uploads, class_name: CommonsUpload
  has_many :training_modules_users, class_name: 'TrainingModulesUsers'

  scope :admin, -> { where(permissions: Permissions::ADMIN) }
  scope :trained, -> { where(trained: true) }
  scope :untrained, -> { where(trained: false) }
  scope :current, -> { joins(:courses).merge(Course.current).distinct }
  scope :role, lambda { |role|
    roles = { 'student' => CoursesUsers::Roles::STUDENT_ROLE,
              'instructor' => CoursesUsers::Roles::INSTRUCTOR_ROLE,
              'online_volunteer' => CoursesUsers::Roles::ONLINE_VOLUNTEER_ROLE,
              'campus_volunteer' => CoursesUsers::Roles::CAMPUS_VOLUNTEER_ROLE,
              'wiki_ed_staff' => CoursesUsers::Roles::WIKI_ED_STAFF_ROLE }
    joins(:courses_users).where(courses_users: { role: roles[role] })
  }

  scope :trained, -> { where(trained: true) }
  scope :ungreeted, -> { where(greeted: false) }

  ####################
  # Instance methods #
  ####################
  def roles(_course)
    {
      id: id,
      admin: admin?
    }
  end

  def talk_page
    "User_talk:#{username}"
  end

  def admin?
    permissions == Permissions::ADMIN
  end

  def instructor?(course)
    course.users.role('instructor').include? self
  end

  # A user is a returning instructor if they have at least one approved course
  # where they are an instructor.
  def returning_instructor?
    courses.any? { |course| instructor?(course) && !course.cohorts.empty? }
  end

  def student?(course)
    course.users.role('student').include? self
  end

  def role(course)
    # If this is a new course, grant permissions.
    return CoursesUsers::Roles::INSTRUCTOR_ROLE if course.nil?
    # Give admins the instructor permissions.
    return CoursesUsers::Roles::INSTRUCTOR_ROLE if admin?

    course_user = course.courses_users.where(user_id: id).order('role DESC').first
    return course_user.role unless course_user.nil?

    # User is in visitor role, if no other role found.
    CoursesUsers::Roles::VISITOR_ROLE
  end

  def can_edit?(course)
    return true if admin?
    editing_roles = [CoursesUsers::Roles::INSTRUCTOR_ROLE,
                     CoursesUsers::Roles::CAMPUS_VOLUNTEER_ROLE,
                     CoursesUsers::Roles::ONLINE_VOLUNTEER_ROLE,
                     CoursesUsers::Roles::WIKI_ED_STAFF_ROLE]
    editing_roles.include? role(course)
  end

  # Exclude tokens/secrets from json output
  def to_json(options={})
    options[:except] ||= [:wiki_token, :wiki_secret, :remember_token]
    super(options)
  end

  private

  def ensure_valid_email
    self.email = nil if ValidatesEmailFormatOf::validate_email_format(email)
  end
end
