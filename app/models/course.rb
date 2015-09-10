# == Schema Information
#
# Table name: courses
#
#  id                :integer          not null, primary key
#  title             :string(255)
#  created_at        :datetime
#  updated_at        :datetime
#  start             :date
#  end               :date
#  school            :string(255)
#  term              :string(255)
#  character_sum     :integer          default(0)
#  view_sum          :integer          default(0)
#  user_count        :integer          default(0)
#  article_count     :integer          default(0)
#  revision_count    :integer          default(0)
#  slug              :string(255)
#  listed            :boolean          default(TRUE)
#  untrained_count   :integer          default(0)
#  meeting_days      :string(255)
#  signup_token      :string(255)
#  assignment_source :string(255)
#  subject           :string(255)
#  expected_students :integer
#  description       :text
#  submitted         :boolean          default(FALSE)
#  passcode          :string(255)
#  timeline_start    :date
#  timeline_end      :date
#  day_exceptions    :string(255)      default("")
#  weekdays          :string(255)      default("0000000")
#  new_article_count :integer
#

require "#{Rails.root}/lib/importers/course_importer"
require "#{Rails.root}/lib/importers/user_importer"

#= Course model
class Course < ActiveRecord::Base
  LEGACY_COURSE_MAX_ID = 9999

  has_many :tags
  has_many :courses_users, class_name: CoursesUsers
  has_many :users, -> { uniq }, through: :courses_users,
                                after_remove: :cleanup_articles
  has_many :students, -> { where('courses_users.role = 0') },
           through: :courses_users, source: :user
  has_many :instructors, -> { where('courses_users.role = 1') },
           through: :courses_users, source: :user
  has_many :volunteers, -> { where('courses_users.role > 1') },
           through: :courses_users, source: :user

  has_many :revisions, -> (course) {
    where('date >= ?', course.start).where('date <= ?', course.end)
  }, through: :students

  has_many :cohorts_courses, class_name: CohortsCourses
  has_many :cohorts, through: :cohorts_courses

  has_many :articles_courses, class_name: ArticlesCourses
  has_many :articles, -> { uniq }, through: :articles_courses

  has_many :uploads, through: :students

  has_many :assignments

  has_many :weeks
  has_many :blocks, through: :weeks
  has_many :gradeables, as: :gradeable_item

  scope :current, lambda {
    current_and_future.where('start < ?', Time.now)
  }

  # A course stays "current" for a while after the end date, during which time
  # we still check for new data and update page views.
  scope :current_and_future, lambda {
    update_length = Figaro.env.update_length.to_i.days.seconds.to_i
    where('end > ?', Time.now - update_length)
  }

  # Courses sourced from Wikipedia, not created with this tool
  scope :legacy, -> { where('courses.id < 10000') }

  before_save :order_weeks

  validates :passcode, presence: true, unless: :is_legacy_course?

  ####################
  # Instance methods #
  ####################
  def to_param
    # This method is used by ActiveRecord
    slug
  end

  def wiki_title
    # Legacy courses using the EducationProgram extension have ids under 10000.
    prefix = id < 10000 ? 'Education_Program:' : Figaro.env.course_prefix + '/'
    escaped_slug = slug.gsub(' ', '_')
    "#{prefix}#{escaped_slug}"
  end

  def url
    language = Figaro.env.wiki_language
    "https://#{language}.wikipedia.org/wiki/#{wiki_title}"
  end

  def delist
    self.listed = false
    save
  end

  def update(data={}, save=true)
    if data.blank?
      data = CourseImporter.get_course_info id
      return if data.blank? || data[0].nil?
      data = data[0]
    end
    self.attributes = data['course']

    return unless save
    if data['participants']
      data['participants'].each_with_index do |(r, _p), i|
        UserImporter.add_users(data['participants'][r], i, self)
      end
    end
    self.save
  end

  def students_without_instructor_students
    students.where.not(id: instructors.pluck(:id))
  end

  def trained_students_without_instructor_students
    students_without_instructor_students.trained
  end

  def untrained_students_without_instructor_students
    students_without_instructor_students.untrained
  end

  #################
  # Cache methods #
  #################
  def character_sum
    update_cache unless self[:character_sum]
    self[:character_sum]
  end

  def view_sum
    update_cache unless self[:view_sum]
    self[:view_sum]
  end

  def user_count
    self[:user_count] || students_without_instructor_students.size
  end

  def untrained_count
    update_cache unless self[:untrained_count]
    self[:untrained_count]
  end

  def revision_count
    self[:revision_count] || revisions.size
  end

  def article_count
    self[:article_count] || articles.namespace(0).live.size
  end

  def new_article_count
    self[:new_article_count] || articles_courses.live.new_article
      .joins(:article).where('articles.namespace = 0')
      .size
  end

  def update_cache
    # Do not consider revisions with negative byte changes
    self.character_sum = courses_users.where(role: 0).sum(:character_sum_ms)
    self.view_sum = articles_courses.live.sum(:view_count)
    self.user_count = students_without_instructor_students.size
    self.untrained_count = untrained_students_without_instructor_students.size
    self.revision_count = revisions.size
    self.article_count = articles.namespace(0).live.size
    self.new_article_count = articles_courses.live.new_article
      .joins(:article).where('articles.namespace = 0')
      .size
    save
  end

  def manual_update
    Dir["#{Rails.root}/lib/importers/*.rb"].each { |file| require file }

    update
    UserImporter.update_users users
    RevisionImporter.update_all_revisions self
    ViewImporter.update_views articles.namespace(0)
      .find_in_batches(batch_size: 30)
    RatingImporter.update_ratings articles.namespace(0)
      .find_in_batches(batch_size: 30)
    Article.update_all_caches articles
    User.update_all_caches users
    ArticlesCourses.update_all_caches articles_courses
    CoursesUsers.update_all_caches courses_users
    update_cache
  end

  ####################
  # Callback methods #
  ####################
  def cleanup_articles(user)
    # find which course articles this user contributed to
    user_articles = user.revisions
                    .where('date >= ? AND date <= ?', start, self.end)
                    .pluck(:article_id)
    course_articles = articles.pluck(:id)
    possible_deletions = course_articles & user_articles

    # have these articles been edited by other students in this course?
    to_delete = []
    possible_deletions.each do |pd|
      other_editors = Article.find(pd).editors - [user.id]
      course_editors = students & other_editors
      to_delete.push pd if other_editors.empty? || course_editors.empty?
    end

    # remove orphaned articles from the course
    articles.delete(Article.find(to_delete))

    # update course cache to account for removed articles
    update_cache unless to_delete.empty?
  end

  #################
  # Class methods #
  #################
  def self.update_all_caches
    Course.transaction do
      Course.current.each(&:update_cache)
    end
  end

  def reorder_weeks
    order_weeks
  end

  private

  def order_weeks
    weeks.each_with_index do |week, i|
      week.update_attribute(:order, i + 1)
    end
  end

  # for use in validation
  def is_legacy_course?
    return true unless Course.any?
    Course.last.id <= LEGACY_COURSE_MAX_ID
  end
end
