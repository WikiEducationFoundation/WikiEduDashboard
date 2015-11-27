# == Schema Information
#
# Table name: users
#
#  id                  :integer          not null, primary key
#  wiki_id             :string(255)
#  created_at          :datetime
#  updated_at          :datetime
#  character_sum       :integer          default(0)
#  view_sum            :integer          default(0)
#  course_count        :integer          default(0)
#  article_count       :integer          default(0)
#  revision_count      :integer          default(0)
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
#

require "#{Rails.root}/lib/utils"

#= User model
class User < ActiveRecord::Base
  #############
  # Constants #
  #############
  module Permissions
    NONE  = 0
    ADMIN = 1
  end

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :rememberable, :omniauthable, omniauth_providers: [:mediawiki, :mediawiki_signup]

  has_many :courses_users, class_name: CoursesUsers
  has_many :courses, -> { uniq }, through: :courses_users
  has_many :revisions, -> { where(system: false) }
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
    language = ENV['wiki_language']
    "https://#{language}.wikipedia.org/wiki/Special:Contributions/#{wiki_id}"
  end

  def sandbox_url
    language = ENV['wiki_language']
    "https://#{language}.wikipedia.org/wiki/Special:PrefixIndex/User:#{wiki_id}"
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
    return 1 if course.nil? # If this is a new course, grant permissions.
    return CoursesUsers::Roles::INSTRUCTOR_ROLE if admin? # Give admins the instructor permissions.

    course_user = course.courses_users.where(user_id: id).order('role DESC').first
    return course_user.role unless course_user.nil?

    CoursesUsers::Roles::VISITOR_ROLE # User is in visitor role, if no other role found.
  end

  def can_edit?(course)
    return true if admin?
    editing_roles = [CoursesUsers::Roles::INSTRUCTOR_ROLE,
                     CoursesUsers::Roles::CAMPUS_VOLUNTEER_ROLE,
                     CoursesUsers::Roles::ONLINE_VOLUNTEER_ROLE,
                     CoursesUsers::Roles::WIKI_ED_STAFF_ROLE]
    editing_roles.include? role(course)
  end

  #################
  # Cache methods #
  #################
  def view_sum
    self[:view_sum] || articles.map(&:views).inject(:+) || 0
  end

  def course_count
    self[:course_count] || courses.size
  end

  def revision_count(after_date=nil)
    if after_date.nil?
      self[:revision_count] || revisions.size
    else
      revisions.after_date(after_date).size
    end
  end

  def article_count
    self[:article_count] || article.size
  end

  def update_cache
    # TODO: Remove character sum and view sum? We use these for CoursesUsers
    # and for Courses, but not for Users.
    self.character_sum = get_character_sum(0)
    self.view_sum = articles.map { |a| a.views || 0 }.inject(:+) || 0
    self.revision_count = revisions.size
    self.article_count = articles.size
    self.course_count = courses.size
    save
  end

  def get_character_sum(namespace)
    # Do not consider revisions with negative byte changes
    Revision.joins(:article)
      .where(articles: { namespace: namespace })
      .where(user_id: id)
      .where('characters >= 0')
      .sum(:characters) || 0
  end

  #################
  # Class methods #
  #################
  def self.update_all_caches(users=nil)
    Utils.run_on_all(User, :update_cache, users)
  end
end
