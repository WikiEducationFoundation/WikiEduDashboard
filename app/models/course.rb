require "#{Rails.root}/lib/importers/course_importer"
require "#{Rails.root}/lib/importers/user_importer"

#= Course model
class Course < ActiveRecord::Base
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

  has_many :assignments

  has_many :weeks
  has_many :blocks, through: :weeks
  has_many :gradeables, as: :gradeable_item

  # A course stays "current" for a while after the end date, during which time
  # we still check for new data and update page views.
  scope :current, lambda {
    update_length = Figaro.env.update_length.to_i.days.seconds.to_i
    where('start < ?', Time.now).where('end > ?', Time.now - update_length)
  }

  ####################
  # Instance methods #
  ####################
  def to_param
    # This method is used by ActiveRecord
    slug
  end

  def to_custom_json
    as_json(
      include: {
        weeks: {
          include: { blocks: { include: :gradeable } }
        },
        courses_users: {
          only: [:character_sum_ms, :character_sum_us, :role],
          include: {
            user: {
              only: [:id, :wiki_id],
              include: {
                assignments: { only: [:article_title] },
                assignments_users: {
                  only: [],
                  include: {
                    user: { only: [:wiki_id] }
                  }
                },
                revisions: {
                  only: [:id, :characters, :views, :date],
                  include: { article: { only: [:title] } }
                }
              }
            }
          }
        }
      }
    )
  end

  def url
    language = Figaro.env.wiki_language
    escaped_slug = slug.gsub(' ', '_')
    "https://#{language}.wikipedia.org/wiki/Education_Program:#{escaped_slug}"
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
    self[:user_count] || users.role('student').size
  end

  def untrained_count
    update_cache unless self[:untrained_count]
    self[:untrained_count]
  end

  def revision_count
    self[:revision_count] || revisions.size
  end

  def article_count
    self[:article_count] || articles.size
  end

  def update_cache
    # Do not consider revisions with negative byte changes
    self.character_sum = courses_users.where(role: 0).sum(:character_sum_ms)
    self.view_sum = articles_courses.live.sum(:view_count)
    self.user_count = users.role('student').size
    self.untrained_count = users.role('student').where(trained: false).size
    self.revision_count = revisions.size
    self.article_count = articles.live.size
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
end
