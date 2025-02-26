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
#  view_sum              :bigint           default(0)
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
#  syllabus_file_size    :bigint
#  syllabus_updated_at   :datetime
#  home_wiki_id          :integer
#  recent_revision_count :integer          default(0)
#  needs_update          :boolean          default(FALSE)
#  chatroom_id           :string(255)
#  flags                 :text(65535)
#  level                 :string(255)
#  private               :boolean          default(FALSE)
#  withdrawn             :boolean          default(FALSE)
#  references_count      :integer          default(0)
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
  has_one :course_stat, class_name: 'CourseStat', dependent: :destroy

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
  has_many :sandboxes, -> { distinct.sandbox }, source: :article, through: :revisions

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

  has_many :course_wiki_namespaces, class_name: 'CourseWikiNamespaces', through: :courses_wikis

  has_many :article_course_timeslices, dependent: :destroy
  has_many :course_user_wiki_timeslices, dependent: :destroy
  has_many :course_wiki_timeslices, dependent: :destroy

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
    Course.includes(:campaigns).where(campaigns: { id: nil })
          .where(submitted: true).references(:campaigns)
          .order('timeline_start')
  end

  def self.unsubmitted
    Course.includes(:campaigns).where(campaigns: { id: nil })
          .where(submitted: false).references(:campaigns)
  end

  def self.classroom_program_students
    nonprivate
      .where(type: 'ClassroomProgramCourse', withdrawn: false)
      .joins(:campaigns)
      .distinct
      .includes(:students)
  end

  def self.classroom_program_students_and_instructors
    nonprivate
      .where(type: 'ClassroomProgramCourse', withdrawn: false)
      .joins(:campaigns)
      .distinct
      .includes(:students, :instructors)
  end

  def self.fellows_cohort_students
    nonprivate
      .where(type: 'FellowsCohort', withdrawn: false)
      .joins(:campaigns)
      .distinct
      .includes(:students)
  end

  def self.fellows_cohort_students_and_instructors
    nonprivate
      .where(type: 'FellowsCohort', withdrawn: false)
      .joins(:campaigns)
      .distinct
      .includes(:students, :instructors)
  end

  scope :strictly_current, -> { where('? BETWEEN start AND end', Time.zone.now) }
  scope :current, -> { current_and_future.where('start < ?', Time.zone.now) }
  scope :ended, -> { where('end < ?', Time.zone.now) }
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

  scope :needs_partial_update, lambda {
    joins(:course_wiki_timeslices)
      .where(course_wiki_timeslices: { needs_update: true })
      .distinct
  }

  scope :current_or_set_to_full_update, -> { current.or(where(needs_update: true)) }

  def self.ready_for_update
    ready_for_update = current_or_set_to_full_update + needs_partial_update
    ready_for_update.uniq
  end

  def self.will_be_ready_for_survey(opts)
    days_offset, before, relative_to = opts.values_at(:days, :before, :relative_to)
    today = Time.zone.now
    ready_date = before ? today + days_offset.days : today - days_offset.days
    where("courses.#{relative_to} > '#{ready_date}'")
  end

  def self.ready_for_survey(opts)
    days_offset, before, relative_to = opts.values_at(:days, :before, :relative_to)
    today = Time.zone.now
    ready_date = before ? today + days_offset.days : today - days_offset.days
    where("courses.#{relative_to} <= '#{ready_date}'")
  end

  ###########
  # Aliases #
  ###########
  alias_attribute :institution, :school

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
  before_save :set_needs_update_for_timeslice
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

  # title can be a string or a Regexp
  def find_block_by_title(title)
    title_matcher = Regexp.new(title)
    blocks.find { |block| block.title =~ title_matcher }
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

  def tracked_namespaces
    courses_wikis.map do |course_wiki|
      wiki = course_wiki.wiki
      wiki_namespaces = course_wiki.course_wiki_namespaces
      if wiki_namespaces.length.zero?
        { wiki:, namespace: 0 }
      else
        wiki_namespaces.map do |wiki_ns|
          { wiki:, namespace: wiki_ns.namespace }
        end
      end
    end.flatten
  end

  # The default implemention retrieves all the revisions.
  # A course type may override this implementation.
  def filter_revisions(_wiki, revisions)
    revisions
  end

  def scoped_article_titles
    assigned_article_titles + category_article_titles
  end

  def assigned_article_titles
    assignments.pluck(:article_title)
  end

  def category_article_titles
    categories.inject([]) { |ids, cat| ids + cat.article_titles }
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

  # Retrieve articles based on the existing article course timeslices.
  # This includes both tracked and untracked articles, such as those that
  # don't belong to a tracked namespace.
  def articles_from_timeslices(wiki_id)
    Article.joins(:article_course_timeslices)
           .where(article_course_timeslices: { course_id: id })
           .where(wiki_id:)
           .distinct
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

  def edited_articles_courses
    articles_courses.tracked.live
  end

  def new_articles_courses
    edited_articles_courses.new_article
  end

  def new_articles_on(wiki)
    new_articles_courses.where("articles.wiki_id = #{wiki.id}")
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

  def add_flag(key:, value: true)
    flags[key] = value
    save
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

  def controlled_by_event_center?
    flags[:event_sync].present?
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

  def retain_available_articles?
    flags[:retain_available_articles].present?
  end

  def disable_student_emails?
    flags[:disable_student_emails].present?
  end

  def review_bibliography?
    flags[:review_bibliography].present?
  end

  def very_long_update?
    flags[:very_long_update].present?
  end

  # TODO: find a better way to check if the course was already updated
  def was_course_ever_updated?
    flags['update_logs'].present?
  end

  # Overridden for ClassroomProgramCourse
  def progress_tracker_enabled?
    false
  end

  # Overridden for some course types
  def cloneable?
    !tag?('no_clone')
  end

  def returning_instructor?
    tag?('returning_instructor')
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

  def approved_at
    campaigns_courses.first&.created_at
  end

  def no_sandboxes?
    flags[:no_sandboxes].present?
  end

  #################
  # Cache methods #
  #################

  def update_cache
    CourseCacheManager.new(self).update_cache
  end

  def update_cache_from_timeslices
    CourseCacheManager.new(self).update_cache_from_timeslices course_wiki_timeslices
  end

  #################
  # Class methods #
  #################
  def self.update_all_caches
    ready_for_update.each(&:update_cache)
  end

  # Ensures weeks for a course have order 1..weeks.count
  # This is dangerous if creating or reordering timeline content except via
  # TimelineController, where every week is processed from the submitted params,
  # and blocks get resorted to the appropriate week if necessary.
  # Weeks are expected to have the same order as their ids.
  def reorder_weeks
    weeks.each_with_index do |week, i|
      week.update(order: i + 1)
    end
  end

  # Makes sure that the home wiki
  # is always a part of courses wikis.
  def ensure_home_wiki_in_courses_wikis
    return if wikis.include? home_wiki
    wikis.push(home_wiki)
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

  # If the start date changed, set needs_update to 'true' for the (maybe new)
  # first course timeslice for every wiki.
  # If the end date changed, set needs_update to 'true' for the (maybe new)
  # end course timeslice for every wiki.
  # We need to do this now because we might not be able to identify a change
  # in the start date after.
  def set_needs_update_for_timeslice
    wikis.each do |wiki|
      update_timeslice_if_exists(wiki, start) if start_changed?
      update_timeslice_if_exists(wiki, self.end) if end_changed?
    end
  end

  def update_timeslice_if_exists(wiki, date)
    timeslice = CourseWikiTimeslice.for_course_and_wiki(self, wiki).for_datetime(date).first
    return unless timeslice
    timeslice.update(needs_update: true)
  end
end
