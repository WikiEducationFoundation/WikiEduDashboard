# == Schema Information
#
# Table name: users
#
#  id                  :integer          not null, primary key
#  username             :string(255)
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
#

require "#{Rails.root}/lib/utils"

#= User model
class User < ActiveRecord::Base
  alias_attribute :wiki_id, :username

  validates :permissions, inclusion: { in: [0, 1, 2] }

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
  has_many :courses, -> { uniq }, through: :courses_users
  has_many :revisions, -> { where(system: false) }
  has_many :all_revisions, class_name: Revision
  has_many :articles, -> { uniq }, through: :revisions
  has_many :assignments
  has_many :uploads, class_name: CommonsUpload
  has_many :training_modules_users, class_name: 'TrainingModulesUsers'

  scope :admin, -> { where(permissions: Permissions::ADMIN) }
  scope :trained, -> { where(trained: true) }
  scope :untrained, -> { where(trained: false) }
  scope :current, -> { joins(:courses).merge(Course.current).uniq }
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

  def contribution_url
    "#{home_wiki.base_url}/wiki/Special:Contributions/#{wiki_id}"
  end

  # Provides a link to the list of all of a user's subpages, ie, sandboxes.
  def sandbox_url
    "#{home_wiki.base_url}/wiki/Special:PrefixIndex/User:#{wiki_id}"
  end

  def talk_page
    "User_talk:#{username}"
  end

  def home_wiki
    # TODO: Let the user select their home_wiki in preferences, and set initial
    # home_wiki to that of the first course the user joins.
    Wiki.default_wiki
  end

  def admin?
    permissions == Permissions::ADMIN
  end

  def instructor?(course)
    course.users.role('instructor').include? self
  end

  def returning_instructor?
    # A user is a returning instructor if they have more than one course in the
    # system. They become a returning instructor as soon as their second course
    # is created, before they go through the assignment wizard.
    courses_users.where(role: CoursesUsers::Roles::INSTRUCTOR_ROLE).count > 1
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
end
