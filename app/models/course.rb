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
#  signup_token      :string(255)
#  assignment_source :string(255)
#  subject           :string(255)
#  expected_students :integer
#  description       :text(65535)
#  submitted         :boolean          default(FALSE)
#  passcode          :string(255)
#  timeline_start    :date
#  timeline_end      :date
#  day_exceptions    :string(2000)      default("")
#  weekdays          :string(255)      default("0000000")
#  new_article_count :integer
#  order             :integer          default(1), not null
#  no_day_exceptions :boolean          default(FALSE)
#  trained_count     :integer          default(0)
#  cloned_status     :integer
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
  has_many(:revisions, lambda do |course|
    where('date >= ?', course.start).where('date <= ?', course.end)
  end, through: :students)

  has_many(:uploads, lambda do |course|
    where('uploaded_at >= ?', course.start).where('uploaded_at <= ?', course.end)
  end, through: :students)

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
  scope :legacy, -> { where(type: 'LegacyCourse') }
  scope :not_legacy, -> { where.not(type: 'LegacyCourse') }

  scope(:unsubmitted_listed, lambda do
    where(submitted: false).where(listed: true).merge(Course.not_legacy)
  end)

  scope :listed, -> { where(listed: true) }

  CLONED_STATUSES = {
    'PENDING' => 1,
    'COMPLETED' => 2
  }

  scope :strictly_current, -> { where('? BETWEEN start AND end', Time.zone.now) }
  scope :current, -> { current_and_future.where('start < ?', Time.zone.now) }
  # A course stays "current" for a while after the end date, during which time
  # we still check for new data and update page views. To exclude those courses
  # use "strictly_current".
  UPDATE_LENGTH = ENV['update_length'].to_i.days.seconds.to_i

  scope :current_and_future, lambda {
    where('end > ?', Time.zone.now - UPDATE_LENGTH)
  }

  scope :archived, lambda {
    where('end <= ?', Time.zone.now - UPDATE_LENGTH)
  }

  ##################
  # Course content #
  ##################
  has_many :weeks, dependent: :destroy
  has_many :blocks, through: :weeks, dependent: :destroy
  has_many :gradeables, as: :gradeable_item, dependent: :destroy

  before_save :order_weeks
  validates :passcode, presence: true, unless: :legacy?

  COURSE_TYPES = %w(
    LegacyCourse
    ClassroomProgramCourse
    VisitingScholarship
    Editathon
  )
  validates_inclusion_of :type, in: COURSE_TYPES

  ####################
  # Callbacks        #
  ####################

  before_save :ensure_required_params

  ####################
  # Instance methods #
  ####################
  delegate :students_without_overdue_training, to: :trained_students_manager

  def to_param
    # This method is used by ActiveRecord
    slug
  end

  def legacy?
    type == 'LegacyCourse'
  end

  def current?
    start < Time.zone.now && self.end > Time.zone.now - UPDATE_LENGTH
  end

  def training_modules
    ids = Block.joins(:week).where(weeks: { course_id: id })
          .where.not('training_module_ids = ?', [].to_yaml)
          .collect(&:training_module_ids).flatten
    TrainingModule.all.select { |tm| ids.include?(tm.id) }
  end

  def url
    return unless wiki_title
    language = ENV['wiki_language']
    "https://#{language}.wikipedia.org/wiki/#{wiki_title}"
  end

  def delist
    self.listed = false
    save
  end

  # LegacyCourse overrides this.
  def update(data={}, should_save=true)
    self.attributes = data[:course]
    save if should_save
  end

  def students_without_nonstudents
    students.where.not(id: nonstudents.pluck(:id))
  end

  def new_articles
    articles_courses.live.new_article
      .joins(:article).where('articles.namespace = 0')
  end

  def word_count
    require "#{Rails.root}/lib/word_count"
    WordCount.from_characters(character_sum)
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
    self.character_sum = courses_users
      .where(role: CoursesUsers::Roles::STUDENT_ROLE)
      .sum(:character_sum_ms)
    self.view_sum = articles_courses.live.sum(:view_count)
    self.user_count = students_without_nonstudents.size
    self.trained_count = calculate_trained_count
    self.revision_count = revisions.size
    self.article_count = articles.namespace(0).live.size
    self.new_article_count = new_articles.count
    save
  end

  def calculate_trained_count
    # The cutoff date represents the switch from on-wiki training, indicated by
    # the 'trained' attribute of a User, to the in-dashboard training module
    # system introduced for the beginning of 2016. For courses after the cutoff
    # date, 'trained_count' is represents the count of students who don't have
    # assigned training modules that are overdue.
    if start > CourseTrainingProgressManager::TRAINING_BOOLEAN_CUTOFF_DATE
      students_without_overdue_training
    else
      students_without_nonstudents.trained.size
    end
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

  RANDOM_PASSCODE_LENGTH = 8
  def self.generate_passcode
    ('a'..'z').to_a.sample(RANDOM_PASSCODE_LENGTH).join
  end

  def reorder_weeks
    order_weeks
  end

  private

  def trained_students_manager
    TrainedStudentsManager.new(self)
  end

  def order_weeks
    weeks.each_with_index do |week, i|
      week.update_attribute(:order, i + 1)
    end
  end

  def ensure_required_params
    return false unless [title, school, term, slug].count(nil).zero?
  end
end
