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
#  trained_count     :integer          default(0)
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

#= Course model
class Course < ActiveRecord::Base
  ######################
  # Users for a course #
  ######################
  has_many :courses_users, class_name: CoursesUsers, dependent: :destroy
  has_many :users, -> { uniq }, through: :courses_users,
                                after_remove: :cleanup_articles
  has_many :students, -> { where('courses_users.role = 0') },
           through: :courses_users, source: :user
  has_many :nonstudents, -> { where('courses_users.role > 0') },
           through: :courses_users, source: :user
  has_many :instructors, -> { where('courses_users.role = 1') },
           through: :courses_users, source: :user
  has_many :volunteers, -> { where('courses_users.role > 1') },
           through: :courses_users, source: :user

  #########################
  # Activity by the users #
  #########################
  has_many :revisions, -> (course) {
    where('date >= ?', course.start).where('date <= ?', course.end)
  }, through: :students
  has_many :uploads, through: :students

  has_many :articles_courses, class_name: ArticlesCourses, dependent: :destroy
  has_many :articles, -> { uniq }, through: :articles_courses

  has_many :assignments, dependent: :destroy

  ############
  # Metadata #
  ############
  has_many :cohorts_courses, class_name: CohortsCourses, dependent: :destroy
  has_many :cohorts, through: :cohorts_courses

  has_many :tags, dependent: :destroy

  # Legacy courses are ones that are imported from the EducationProgram
  # MediaWiki extension, not created within the dashboard via the wizard.
  LEGACY_COURSE_MAX_ID = 9999
  scope :legacy, -> { where('courses.id <= ?', LEGACY_COURSE_MAX_ID) }
  scope :not_legacy, -> { where('courses.id > ?', LEGACY_COURSE_MAX_ID) }

  scope :unsubmitted_listed, -> {
    where(submitted: false).where(listed: true).merge(Course.not_legacy)
  }

  scope :listed, -> { where(listed: true) }

  CLONED_STATUSES = {
    'PENDING' => 1,
    'COMPLETED' => 2
  }

  ##################
  # Course content #
  ##################
  has_many :weeks, dependent: :destroy
  has_many :blocks, through: :weeks, dependent: :destroy
  has_many :gradeables, as: :gradeable_item, dependent: :destroy

  scope :current, lambda {
    current_and_future.where('start < ?', Time.now)
  }
  # A course stays "current" for a while after the end date, during which time
  # we still check for new data and update page views.
  scope :current_and_future, lambda {
    update_length = ENV['update_length'].to_i.days.seconds.to_i
    where('end > ?', Time.now - update_length)
  }

  before_save :order_weeks
  validates :passcode, presence: true, unless: :legacy?

  ####################
  # Instance methods #
  ####################
  def to_param
    # This method is used by ActiveRecord
    slug
  end

  def legacy?
    # If a course doesn't have an id yet, it's a new, unsaved course, and
    # therefore not a legacy course. Legacy courses get their ids from the wiki.
    return false if id.nil?
    id <= LEGACY_COURSE_MAX_ID
  end

  def wiki_title
    # Legacy courses using the EducationProgram extension have wiki pages
    # in a different namespace on Wikipedia.
    prefix = legacy? ? 'Education_Program:' : ENV['course_prefix'] + '/'
    escaped_slug = slug.gsub(' ', '_')
    "#{prefix}#{escaped_slug}"
  end

  def url
    language = ENV['wiki_language']
    "https://#{language}.wikipedia.org/wiki/#{wiki_title}"
  end

  def delist
    self.listed = false
    save
  end

  def update(data={}, should_save=true)
    # For legacy courses, the update may involve pulling data from MediaWiki
    if legacy?
      require "#{Rails.root}/lib/course_update_manager"
      CourseUpdateManager.update_from_wiki(self, data, should_save)
    # For non-legacy courses, update simply means saving posted attributes.
    else
      self.attributes = data[:course]
      save if should_save
    end
  end

  def students_without_nonstudents
    students.where.not(id: nonstudents.pluck(:id))
  end

  def new_articles
    articles_courses.live.new_article
      .joins(:article).where('articles.namespace = 0')
  end
  #################
  # Cache methods #
  #################
  def character_sum
    return_or_calculate :character_sum
  end

  def view_sum
    return_or_calculate :view_sum
  end

  def user_count
    return_or_calculate :user_count
  end

  def trained_count
    return_or_calculate :trained_count
  end

  def revision_count
    return_or_calculate :revision_count
  end

  def article_count
    return_or_calculate :article_count
  end

  def new_article_count
    return_or_calculate :new_article_count
  end

  def return_or_calculate(attribute)
    update_cache unless self[attribute]
    self[attribute]
  end

  def update_cache
    # Do not consider revisions with negative byte changes
    self.character_sum = courses_users.where(role: 0).sum(:character_sum_ms)
    self.view_sum = articles_courses.live.sum(:view_count)
    self.user_count = students_without_nonstudents.size
    self.trained_count = students_without_nonstudents.trained.size
    self.revision_count = revisions.size
    self.article_count = articles.namespace(0).live.size
    self.new_article_count = new_articles.count
    save
  end

  def manual_update
    require "#{Rails.root}/lib/course_update_manager"
    CourseUpdateManager.manual_update self
  end

  ####################
  # Callback methods #
  ####################
  def cleanup_articles(user)
    require "#{Rails.root}/lib/course_cleanup_manager"
    CourseCleanupManager.cleanup_articles(self, user)
  end

  #################
  # Class methods #
  #################
  def self.update_all_caches
    Course.transaction do
      Course.current.each(&:update_cache)
    end
  end

  def self.submitted_listed
    Course.includes(:cohorts).where('cohorts.id IS NULL')
      .where(listed: true).where(submitted: true)
      .references(:cohorts)
  end

  def self.generate_passcode
    ('a'..'z').to_a.sample(8).join
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
end
