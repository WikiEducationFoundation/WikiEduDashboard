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
#  view_sum              :bigint(8)        default(0)
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
#  recent_revision_count :integer          default(0)
#  needs_update          :boolean          default(FALSE)
#  chatroom_id           :string(255)
#  flags                 :text(65535)
#  level                 :string(255)
#  private               :boolean          default(FALSE)
#  withdrawn             :boolean          default(FALSE)
#

require_dependency "#{Rails.root}/lib/course_cache_manager"
require_dependency "#{Rails.root}/lib/course_training_progress_manager"
require_dependency "#{Rails.root}/lib/trained_students_manager"
require_dependency "#{Rails.root}/lib/word_count"
require_dependency "#{Rails.root}/lib/course_meetings_manager"

#= Course model
class Course < ApplicationRecord
  ######################
  # Users for a course #
  ######################
  has_many :courses_users, class_name: 'CoursesUsers', dependent: :destroy
  has_many :users, -> { distinct }, through: :courses_users
  has_many :students, -> { where('courses_users.role = 0') },
           through: :courses_users, source: :user
  has_many :nonstudents, -> { where('courses_users.role > 0') },
           through: :courses_users, source: :user
  has_many :instructors, -> { where('courses_users.role = 1') },
           through: :courses_users, source: :user
  has_many :volunteers, -> { where('courses_users.role > 1') },
           through: :courses_users, source: :user
  has_many :staff, -> { where('courses_users.role = 4') },
           through: :courses_users, source: :user
  has_many :survey_notifications, dependent: :destroy
  has_many :requested_accounts, dependent: :destroy
  has_many :tickets,
           class_name: 'TicketDispenser::Ticket',
           foreign_key: 'project_id',
           dependent: :destroy

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

  # Same as revisions, but isn't bounded by the course end date
  has_many(:recent_revisions, lambda do |course|
    where('date >= ?', course.start)
  end, through: :students, source: :revisions)

  has_many(:uploads, lambda do |course|
    where('uploaded_at >= ?', course.start).where('uploaded_at <= ?', course.end)
  end, through: :students)

  has_many :articles_courses, class_name: 'ArticlesCourses', dependent: :destroy
  has_many :articles, -> { distinct }, through: :articles_courses
  has_many :pages_edited, -> { distinct }, source: :article, through: :revisions

  has_many :assignments, dependent: :destroy

  has_many :categories_courses, class_name: 'CategoriesCourses', dependent: :destroy
  has_many :categories, through: :categories_courses

  has_many :alerts
  has_many :public_alerts, -> { nonprivate }, class_name: 'Alert'

  ############
  # Metadata #
  ############
  belongs_to :home_wiki, class_name: 'Wiki'

  has_many :campaigns_courses, class_name: 'CampaignsCourses', dependent: :destroy
  has_many :campaigns, through: :campaigns_courses

  has_many :tags, dependent: :destroy

  has_many :courses_wikis, class_name: 'CoursesWikis', dependent: :destroy
  has_many :wikis, through: :courses_wikis

  serialize :flags, Hash

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

  scope :nonprivate, -> { where(private: false) }
  # Legacy courses are ones that are imported from the EducationProgram
  # MediaWiki extension, not created within the dashboard via the wizard.
  scope :legacy, -> { where(type: 'LegacyCourse') }

  def self.submitted_but_unapproved
    Course.includes(:campaigns).where('campaigns.id IS NULL')
          .where(submitted: true).references(:campaigns)
          .order('timeline_start')
  end

  def self.unsubmitted
    Course.includes(:campaigns).where('campaigns.id IS NULL')
          .where(submitted: false).references(:campaigns)
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

  scope :ready_for_update, -> { current.or(where(needs_update: true)) }

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
  has_many :blocks, through: :weeks

  has_attached_file :syllabus
  validates_attachment_content_type :syllabus,
                                    content_type: %w[application/pdf application/msword]

  validates :passcode, presence: true, if: :passcode_required?
  validates :start, presence: true
  validates :end, presence: true
  validates :home_wiki_id, presence: true

  COURSE_TYPES = %w[
    ArticleScopedProgram
    BasicCourse
    ClassroomProgramCourse
    Editathon
    FellowsCohort
    LegacyCourse
    VisitingScholarship
  ].freeze
  validates_inclusion_of :type, in: COURSE_TYPES

  #############
  # Callbacks #
  #############
  before_save :ensure_required_params
  before_save :reorder_weeks
  before_save :set_default_times
  before_save :check_course_times
  before_save :set_needs_update
  after_create :ensure_home_wiki_in_courses_wikis

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

  # Overridden for some course types
  def passcode_required?
    true
  end

  def approved?
    campaigns.any? && !withdrawn
  end

  def closed?
    flags[:closed_date].present?
  end

  def tag?(query_tag)
    tags.pluck(:tag).include? query_tag
  end

  def training_modules
    @training_modules ||= TrainingModule.all.select { |tm| training_module_ids.include?(tm.id) }
  end

  def training_module_ids
    @training_module_ids ||= Block.joins(:week).where(weeks: { course_id: id })
                                  .where.not('training_module_ids = ?', [].to_yaml)
                                  .collect(&:training_module_ids).flatten
  end

  def tracked_revisions
    revisions.where.not(article_id: articles_courses.not_tracked.pluck(:article_id))
             .where(wiki_id: wiki_ids)
  end

  def tracked_articles
    articles.where.not(id: articles_courses.not_tracked.pluck(:article_id))
  end

  def scoped_article_ids
    assigned_article_ids + category_article_ids
  end

  def assigned_article_ids
    assignments.pluck(:article_id)
  end

  def category_article_ids
    categories.inject([]) { |ids, cat| ids + cat.article_ids }
  end

  def update_until
    self.end + UPDATE_LENGTH
  end

  def wiki_page?
    wiki_course_page_enabled? && home_wiki.edits_enabled?
  end

  def wiki_title
    return nil unless wiki_page?
    escaped_slug = slug.tr(' ', '_') # follow MediaWiki page name conventions: undescores for spaces
    "#{home_wiki.course_prefix}/#{escaped_slug}"
  end

  def update_wikis(updated_wikis)
    update(wikis: updated_wikis)
    ensure_home_wiki_in_courses_wikis
  end

  # The url for the on-wiki version of the course.
  def url
    # Some courses do not have corresponding on-wiki pages, so they have no wiki_title or url.
    return unless wiki_page?
    "#{home_wiki.base_url}/wiki/#{wiki_title}"
  end

  def new_articles
    articles_courses.tracked.live.new_article.joins(:article).where('articles.namespace = 0')
  end

  def new_articles_on(wiki)
    new_articles.where("articles.wiki_id = #{wiki.id}")
  end

  def uploads_in_use
    uploads.where('usage_count > 0')
  end

  def word_count
    @word_count ||= WordCount.from_characters(character_sum)
  end

  def average_word_count
    return 0 if user_count.zero?
    word_count / user_count
  end

  # Overridden for some course types
  def wiki_edits_enabled?
    return true unless flags.key?(:wiki_edits_enabled)
    flags[:wiki_edits_enabled]
  end

  def edit_settings
    flags['edit_settings']
  end

  def academic_system
    flags['academic_system']
  end

  def format
    flags['format']
  end

  def edit_settings_present?
    flags.key?('edit_settings')
  end

  def wiki_course_page_enabled?
    edit_settings['wiki_course_page_enabled']
  end

  # Overridden for some course types
  def assignment_edits_enabled?
    return false unless wiki_edits_enabled?
    return true unless edit_settings_present?
    edit_settings['assignment_edits_enabled']
  end

  def enrollment_edits_enabled?
    return false unless wiki_edits_enabled?
    return true unless edit_settings_present?
    edit_settings['enrollment_edits_enabled']
  end

  def peer_review_count
    flags[:peer_review_count]
  end

  # An extra param added to some wiki output.
  # Overridden by FellowsCohort.
  def wiki_template_param
    nil
  end

  # Overidden by ClassroomProgramCourse
  def timeline_enabled?
    flags[:timeline_enabled].present?
  end

  def online_volunteers_enabled?
    flags[:online_volunteers_enabled].present?
  end

  def stay_in_sandbox?
    flags[:stay_in_sandbox].present?
  end

  # Overridden for some course types
  def cloneable?
    !tag?('no_clone')
  end

  # Overridden for some course types
  def training_library_slug
    'students'
  end

  def account_requests_enabled?
    return true if flags[:register_accounts].present?
    campaigns.exists?(register_accounts: true)
  end

  def meetings_manager
    @meetings_manager ||= CourseMeetingsManager.new(self)
  end

  def training_progress_manager
    @training_progress_manager ||= CourseTrainingProgressManager.new(self)
  end

  def submitted_at
    tags.find_by(tag: 'submitted')&.created_at
  end

  #################
  # Cache methods #
  #################

  def update_cache
    CourseCacheManager.new(self).update_cache
  end

  #################
  # Class methods #
  #################
  def self.update_all_caches
    ready_for_update.each(&:update_cache)
  end

  def self.update_all_caches_concurrently(concurrency = 2)
    threads = ready_for_update
              .in_groups(concurrency, false)
              .map.with_index do |course_batch, i|
      Thread.new(i) { course_batch.each(&:update_cache) }
    end
    threads.each(&:join)
  end

  # Ensures weeks for a course have order 1..weeks.count
  # This is dangerous if creating or reordering timeline content except via
  # TimelineController, where every week is processed from the submitted params,
  # and blocks get resorted to the appropriate week if necessary.
  # Weeks are expected to have the same order as their ids.
  def reorder_weeks
    weeks.each_with_index do |week, i|
      week.update_attribute(:order, i + 1)
    end
  end

  # Makes sure that the home wiki
  # is always a part of courses wikis.
  def ensure_home_wiki_in_courses_wikis
    wikis.push(home_wiki) unless wikis.include? home_wiki
  end

  private

  def trained_students_manager
    TrainedStudentsManager.new(self)
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

  # Check if course times are invalid and if yes, set the end time to be the same
  # as that of the start time
  def check_course_times
    self.end = start if start > self.end
  end

  # If the start date changed, set needs_update to `true` so that
  # the stats will be updated to reflect the new start date
  # and the earlier revisions will be fetched.
  def set_needs_update
    self.needs_update = true if start_changed?
  end
end
