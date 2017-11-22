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
#

require "#{Rails.root}/lib/utils"

#= User model
class User < ActiveRecord::Base
  alias_attribute :wiki_id, :username
  before_validation :ensure_valid_email

  #############
  # Constants #
  #############
  module Permissions
    NONE  = 0
    ADMIN = 1
    INSTRUCTOR = 2
  end
  validates :permissions, inclusion: {
    in: [Permissions::NONE, Permissions::ADMIN, Permissions::INSTRUCTOR]
  }

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :rememberable, :omniauthable, omniauth_providers: %i[mediawiki mediawiki_signup]

  has_many :courses_users, class_name: 'CoursesUsers', dependent: :destroy
  has_many :campaigns_users, class_name: 'CampaignsUsers', dependent: :destroy
  has_many :survey_notifications, through: :courses_users
  has_many :courses, -> { distinct }, through: :courses_users

  has_many :instructor_roles, -> { where(role: CoursesUsers::Roles::INSTRUCTOR_ROLE) },
           class_name: 'CoursesUsers'
  has_many :instructed_courses, through: :instructor_roles, source: :course
  has_many :staff_roles, -> { where(role: CoursesUsers::Roles::WIKI_ED_STAFF_ROLE) },
           class_name: 'CoursesUsers'
  has_many :supported_courses, -> { distinct }, through: :staff_roles, source: :course

  has_many :campaigns, -> { distinct }, through: :campaigns_users
  has_many :revisions, -> { where(system: false) }
  has_many :all_revisions, class_name: 'Revision'
  has_many :articles, -> { distinct }, through: :revisions
  has_many :assignments
  has_many :uploads, class_name: 'CommonsUpload'
  has_many :training_modules_users, class_name: 'TrainingModulesUsers'
  has_one :user_profile, dependent: :destroy

  has_many :assignment_suggestions

  scope :admin, -> { where(permissions: Permissions::ADMIN) }
  scope :instructor, -> { where(permissions: Permissions::INSTRUCTOR) }
  scope :trained, -> { where(trained: true) }
  scope :ungreeted, -> { where(greeted: false) }

  scope :current, -> { joins(:courses).merge(Course.current).distinct }
  scope :strictly_current, -> { joins(:courses).merge(Course.strictly_current) }
  scope :from_courses, lambda { |courses|
    joins(:courses_users).where(courses_users: { course: courses })
  }
  scope :role, lambda { |role|
    roles = { 'student' => CoursesUsers::Roles::STUDENT_ROLE,
              'instructor' => CoursesUsers::Roles::INSTRUCTOR_ROLE,
              'online_volunteer' => CoursesUsers::Roles::ONLINE_VOLUNTEER_ROLE,
              'campus_volunteer' => CoursesUsers::Roles::CAMPUS_VOLUNTEER_ROLE,
              'wiki_ed_staff' => CoursesUsers::Roles::WIKI_ED_STAFF_ROLE }
    joins(:courses_users).where(courses_users: { role: roles[role] })
  }

  ####################
  # Class method(s)  #
  ####################
  def self.search_by_email(email)
    User.where('lower(email) like ?', "#{email}%")
  end

  def self.search_by_real_name(real_name)
    User.where('lower(real_name) like ?', "%#{real_name}%")
  end

  ####################
  # Instance methods #
  ####################
  def roles(_course)
    { id: id, admin: admin? }
  end

  def talk_page
    "User_talk:#{url_encoded_username}"
  end

  def url_encoded_username
    # Convert spaces to underscores, then URL-encode the rest
    # The spaces-to-underscores is the MediaWiki convention, which we replicate
    # for handling usernames in dashboard urls.
    CGI.escape(username.tr(' ', '_'))
  end

  def admin?
    permissions == Permissions::ADMIN
  end

  def course_instructor?
    courses.any? { |course| instructor?(course) }
  end

  def instructor?(course)
    course.users.role('instructor').include? self
  end

  # A user is a returning instructor if they have at least one approved course
  # where they are an instructor.
  def returning_instructor?
    courses.any? { |course| instructor?(course) && course.approved? }
  end

  def student?(course)
    course.users.role('student').include? self
  end

  def course_student?
    courses.any? { |course| student?(course) }
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
    options[:except] ||= %i[wiki_token wiki_secret remember_token]
    super(options)
  end

  private

  def ensure_valid_email
    self.email = nil if ValidatesEmailFormatOf::validate_email_format(email)
  end
end
