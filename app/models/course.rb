# frozen_string_literal: true
# == Schema Information
#
# Table name: courses
#
#  id                    :integer          not null, primary key
#  title                 :string(255)
#  created_at            :datetime
#  updated_at            :datetime
#  start                 :datetime
#  end                   :datetime
#  school                :string(255)
#  term                  :string(255)
#  character_sum         :integer          default(0)
#  view_sum              :integer          default(0)
#  user_count            :integer          default(0)
#  article_count         :integer          default(0)
#  revision_count        :integer          default(0)
#  slug                  :string(255)
#  subject               :string(255)
#  expected_students     :integer
#  description           :text(65535)
#  submitted             :boolean          default(FALSE)
#  passcode              :string(255)
#  timeline_start        :datetime
#  timeline_end          :datetime
#  day_exceptions        :string(2000)     default("")
#  weekdays              :string(255)      default("0000000")
#  new_article_count     :integer          default(0)
#  no_day_exceptions     :boolean          default(FALSE)
#  trained_count         :integer          default(0)
#  cloned_status         :integer
#  type                  :string(255)      default("ClassroomProgramCourse")
#  upload_count          :integer          default(0)
#  uploads_in_use_count  :integer          default(0)
#  upload_usages_count   :integer          default(0)
#  syllabus_file_name    :string(255)
#  syllabus_content_type :string(255)
#  syllabus_file_size    :integer
#  syllabus_updated_at   :datetime
#  home_wiki_id          :integer
#  timezone              :string           default("UTC")
#

require "#{Rails.root}/lib/course_cleanup_manager"
require "#{Rails.root}/lib/course_cache_manager"
require "#{Rails.root}/lib/course_update_manager"
require "#{Rails.root}/lib/course_training_progress_manager"
require "#{Rails.root}/lib/revision_stat"
require "#{Rails.root}/lib/trained_students_manager"
require "#{Rails.root}/lib/word_count"
require "#{Rails.root}/lib/training_module"

#= Course model
class Course < ActiveRecord::Base
  ######################
  # Users for a course #
  ######################
  has_many :courses_users, class_name: CoursesUsers, dependent: :destroy
  has_many :users, -> { distinct }, through: :courses_users,
                                    after_remove: :cleanup_articles
  has_many :students, -> { where('courses_users.role = 0') },
           through: :courses_users, source: :user
  has_many :nonstudents, -> { where('courses_users.role > 0') },
           through: :courses_users, source: :user
  has_many :instructors, -> { where('courses_users.role = 1') },
           through: :courses_users, source: :user
  has_many :volunteers, -> { where('courses_users.role > 1') },
           through: :courses_users, source: :user
  has_many :survey_notifications, dependent: :destroy

  #########################
  # Activity by the users #
  #########################
  # :revisions and :all_revisions have the same default implementation,
  # but a course type may override :revisions.
  has_many(:revisions, lambda do |course|
    where('date >= ?', course.start).where('date <= ?', course.end)
  end, through: :students)

  has_many(:all_revisions, lambda do |course|
    where('date >= ?', course.start).where('date <= ?', course.end)
  end, through: :students)

  has_many(:uploads, lambda do |course|
    where('uploaded_at >= ?', course.start).where('uploaded_at <= ?', course.end)
  end, through: :students)

  has_many :articles_courses, class_name: ArticlesCourses, dependent: :destroy
  has_many :articles, -> { distinct }, through: :articles_courses
  has_many :pages_edited, -> { distinct }, source: :article, through: :revisions

  has_many :assignments, dependent: :destroy

  ############
  # Metadata #
  ############
  belongs_to :home_wiki, class_name: Wiki

  has_many :cohorts_courses, class_name: CohortsCourses, dependent: :destroy
  has_many :cohorts, through: :cohorts_courses

  has_many :tags, dependent: :destroy

  module ClonedStatus
    NOT_A_CLONE = 0
    # PENDING is the initial cloned record, where the cloning process was
    # initiated, but not completed.
    PENDING = 1
    COMPLETED = 2
  end

  ##########
  # Scopes #
  ##########

  # Legacy courses are ones that are imported from the EducationProgram
  # MediaWiki extension, not created within the dashboard via the wizard.
  scope :legacy, -> { where(type: 'LegacyCourse') }

  def self.submitted_but_unapproved
    Course.includes(:cohorts).where('cohorts.id IS NULL')
          .where(submitted: true).references(:cohorts)
  end

  def self.unsubmitted
    Course.includes(:cohorts).where('cohorts.id IS NULL')
          .where(submitted: false).references(:cohorts)
  end

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

  def self.will_be_ready_for_survey(opts)
    days_offset, before, relative_to = opts.values_at(:days, :before, :relative_to)
    today = Time.zone.now
    ready_date = before ? today + days_offset.days : today - days_offset.days
    where("#{relative_to} > '#{ready_date}'")
  end

  def self.ready_for_survey(opts)
    days_offset, before, relative_to = opts.values_at(:days, :before, :relative_to)
    today = Time.zone.now
    ready_date = before ? today + days_offset.days : today - days_offset.days
    where("#{relative_to} <= '#{ready_date}'")
  end

  ##################
  # Course content #
  ##################
  has_many :weeks, dependent: :destroy
  has_many :blocks, through: :weeks, dependent: :destroy
  has_many :gradeables, as: :gradeable_item, dependent: :destroy

  has_attached_file :syllabus
  validates_attachment_content_type :syllabus,
                                    content_type: %w(application/pdf application/msword)

  validates :passcode, presence: true, unless: :legacy?
  validates :start, presence: true
  validates :end, presence: true

  COURSE_TYPES = %w(
    LegacyCourse
    ClassroomProgramCourse
    VisitingScholarship
    Editathon
    BasicCourse
  ).freeze
  validates_inclusion_of :type, in: COURSE_TYPES

  #############
  # Callbacks #
  #############
  before_save :ensure_required_params
  before_save :order_weeks
  before_save :set_default_times

  ####################
  # Instance methods #
  ####################
  delegate :students_up_to_date_with_training, to: :trained_students_manager
  delegate :students_with_overdue_training, to: :trained_students_manager

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

  # The url for the on-wiki version of the course.
  def url
    # wiki_title is implemented by the specific course type.
    # Some types do not have corresponding on-wiki pages, so they have no
    # wiki_title or url.
    return unless wiki_title
    "#{home_wiki.base_url}/wiki/#{wiki_title}"
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
    articles_courses.live.new_article.joins(:article).where('articles.namespace = 0')
  end

  def uploads_in_use
    uploads.where('usage_count > 0')
  end

  def word_count
    require "#{Rails.root}/lib/word_count"
    WordCount.from_characters(character_sum)
  end

  def average_word_count
    return 0 if user_count.zero?
    word_count / user_count
  end

  #################
  # Cache methods #
  #################

  def update_cache
    CourseCacheManager.new(self).update_cache
  end

  def manual_update
    CourseUpdateManager.manual_update self
  end

  def recent_edit_count
    RevisionStat.get_records(course_id: id)
  end

  ####################
  # Callback methods #
  ####################
  def cleanup_articles(user)
    CourseCleanupManager.new(self, user).cleanup_articles
  end

  #################
  # Class methods #
  #################
  def self.update_all_caches
    Course.current.each(&:update_cache)
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
    # Halt the callback chain and do not save if require params are missing
    throw :abort unless [title, school, term, slug].count(nil).zero?

    self.timeline_start ||= start
    self.timeline_end ||= self.end
  end

  # Override start and end times if the controls are hidden from the interface.
  # use_start_and_end_times is true when the times are user-supplied.
  def set_default_times
    return if use_start_and_end_times
    self.start = start.beginning_of_day
    self.end = self.end.end_of_day
    self.timeline_start = timeline_start.beginning_of_day
    self.timeline_end = timeline_end.end_of_day
  end
end
