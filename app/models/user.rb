require "#{Rails.root}/lib/utils"

#= User model
class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :rememberable, :omniauthable, omniauth_providers: [:mediawiki]

  has_many :courses_users, class_name: CoursesUsers
  has_many :courses, -> { uniq }, through: :courses_users
  has_many :revisions
  has_many :articles, -> { uniq }, through: :revisions
  has_many :assignments
  has_many :uploads, class_name: CommonsUpload

  has_many :assignments_users, class_name: AssignmentsUsers
  has_many :reviewing_assignments, -> { uniq }, through: :assignments_users

  scope :admin, -> { where(permissions: 1) }
  scope :current, -> { joins(:courses).merge(Course.current).uniq }
  scope :role, lambda { |role|
    index = %w(student instructor online_volunteer
               campus_volunteer wiki_ed_staff)
    joins(:courses_users).where(courses_users: { role: index.index(role) })
  }

  ####################
  # Instance methods #
  ####################
  def roles(course)
    {
      id: id,
      role: role(course),
      admin: admin?
    }
  end

  def contribution_url
    language = Figaro.env.wiki_language
    # rubocop:disable Metrics/LineLength
    "https://#{language}.wikipedia.org/wiki/Special:Contributions/#{wiki_id}"
    # rubocop:enable Metrics/LineLength
  end

  def admin?
    permissions == 1
  end

  def instructor?(course)
    course.users.role('instructor').include? self
  end

  def student?(course)
    course.users.role('student').include? self
  end

  def role(course)
    return 1 if course.nil? # This is a new course, grant permissions
    course_user = course.courses_users.where(user_id: id).first
    if admin?
      1                   # give admin instructor permissions
    elsif !course_user.nil?
      course_user.role    # course role
    else
      -1                  # visitor
    end
  end

  def can_edit?(course)
    [1, 4].include? role(course)
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
    # Do not consider revisions with negative byte changes
    self.character_sum = Revision.joins(:article)
      .where(articles: { namespace: 0 })
      .where(user_id: id)
      .where('characters >= 0')
      .sum(:characters) || 0
    self.view_sum = articles.map { |a| a.views || 0 }.inject(:+) || 0
    self.revision_count = revisions.size
    self.article_count = articles.size
    self.course_count = courses.size
    save
  end

  #################
  # Class methods #
  #################
  def self.update_all_caches(users=nil)
    Utils.run_on_all(User, :update_cache, users)
  end
end
