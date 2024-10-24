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

require_dependency "#{Rails.root}/lib/utils"

#= User model
class User < ApplicationRecord
  alias_attribute :wiki_id, :username
  before_validation :ensure_valid_email

  include MediawikiUrlHelper

  #############
  # Constants #
  #############
  module Permissions
    NONE  = 0
    ADMIN = 1
    INSTRUCTOR = 2
    SUPER_ADMIN = 3
  end
  validates :permissions, inclusion: {
    in: [Permissions::NONE, Permissions::ADMIN, Permissions::INSTRUCTOR, Permissions::SUPER_ADMIN]
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

  scope :admin, -> { where(permissions: [Permissions::ADMIN, Permissions::SUPER_ADMIN]) }
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
  def roles(course)
    { id:, admin: admin?, campaign_organizer: campaign_organizer?(course) }
  end

  def talk_page
    "User talk:#{username}"
  end

  def user_page
    "User:#{username}"
  end

  def url_encoded_username
    url_encoded_mediawiki_title username
  end

  def userpage_url(course)
    "#{course.home_wiki.base_url}/wiki/User:#{url_encoded_username}"
  end

  def admin?
    [Permissions::ADMIN, Permissions::SUPER_ADMIN].include? permissions
  end

  def super_admin?
    permissions == Permissions::SUPER_ADMIN
  end

  def instructor_permissions?
    permissions == Permissions::INSTRUCTOR
  end

  def course_instructor?
    @course_instructor ||= courses_users.exists?(role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
  end

  def instructor?(course)
    courses_users.exists?(role: CoursesUsers::Roles::INSTRUCTOR_ROLE, course_id: course.id)
  end

  # A user is a returning instructor if they have at least one approved course
  # where they are an instructor.
  def returning_instructor?
    courses.any? { |course| instructor?(course) && course.approved? }
  end

  def student?(course)
    courses_users.exists?(role: CoursesUsers::Roles::STUDENT_ROLE, course_id: course.id)
  end

  def course_student?
    @course_student ||= courses_users.exists?(role: CoursesUsers::Roles::STUDENT_ROLE)
  end

  def nonvisitor?(course)
    return true if admin?
    !course_roles(course).empty?
  end

  # returns an array of roles a user has in a given course
  def course_roles(course)
    course.courses_users.where(user_id: id).order('role DESC').pluck(:role)
  end

  def highest_role(course)
    roles = course_roles(course)

    return CoursesUsers::Roles::INSTRUCTOR_ROLE if admin?
    return CoursesUsers::Roles::VISITOR_ROLE if roles.empty?

    roles.first
  end

  EDITING_ROLES = [CoursesUsers::Roles::INSTRUCTOR_ROLE,
                   CoursesUsers::Roles::WIKI_ED_STAFF_ROLE].freeze
  def can_edit?(course)
    return true if admin?
    return true if course_roles(course).any? { |role| EDITING_ROLES.include?(role) }
    return true if campaign_organizer?(course)
    false
  end

  def can_view?(course)
    nonvisitor?(course)
  end

  def campaign_organizer?(course)
    CampaignsUsers.exists?(user: self, campaign: course.campaigns,
                           role: CampaignsUsers::Roles::ORGANIZER_ROLE)
  end

  REAL_NAME_ROLES = [CoursesUsers::Roles::INSTRUCTOR_ROLE,
                     CoursesUsers::Roles::WIKI_ED_STAFF_ROLE].freeze
  def can_see_real_names?(course)
    return true if admin?
    course_roles(course).any? { |role| REAL_NAME_ROLES.include?(role) }
  end

  def email_preferences_token
    (user_profile || create_user_profile).email_preferences_token
  end

  # Exclude tokens/secrets from json output
  def to_json(options={})
    options[:except] ||= %i[wiki_token wiki_secret remember_token]
    super(options)
  end

  def profile_image
    return unless user_profile
    user_profile.image&.present? ? user_profile.image.url(:thumb) : user_profile.image_file_link
  end

  private

  def ensure_valid_email
    self.email = nil if ValidatesEmailFormatOf::validate_email_format(email)
  end
end
