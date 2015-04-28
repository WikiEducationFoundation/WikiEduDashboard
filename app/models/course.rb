#= Course model
class Course < ActiveRecord::Base
  has_many :courses_users, class_name: CoursesUsers
  has_many :users, -> { uniq }, through: :courses_users,
                                after_remove: :cleanup_articles
  has_many :students, -> { where('courses_users.role = 0') },
           through: :courses_users, source: :user

  has_many :revisions, -> (course) {
    where('date >= ?', course.start).where('date <= ?', course.end)
  }, through: :students

  has_many :cohorts_courses, class_name: CohortsCourses
  has_many :cohorts, through: :cohorts_courses

  has_many :articles_courses, class_name: ArticlesCourses
  has_many :articles, -> { uniq }, through: :articles_courses

  has_many :assignments

  scope :current, lambda {
    month = 2_592_000 # number of seconds in 30 days
    where('start < ?', Time.now).where('end > ?', Time.now - month)
  }

  ####################
  # Instance methods #
  ####################
  def to_param
    # This method is used by ActiveRecord
    slug
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
      data = Wiki.get_course_info id
      return if data.blank?
      data = data[0]
    end
    self.attributes = data['course']

    return unless save
    data['participants'].each_with_index do |(r, _p), i|
      User.add_users(data['participants'][r], i, self)
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
    update
    User.update_users users
    Revision.update_all_revisions self
    Article.update_views articles.namespace(0).find_in_batches(batch_size: 30)
    Article.update_ratings articles.namespace(0).find_in_batches(batch_size: 30)
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

  # course.cleanup_articles(User.find(19723888)) 419

  #################
  # Class methods #
  #################
  def self.update_all_courses(initial=false, raw_ids={})
    raw_ids = Wiki.course_list if raw_ids.empty?
    listed_ids = raw_ids.values.flatten
    course_ids = listed_ids | Course.where(listed: true).pluck(:id).map(&:to_s)
    
    if initial
      _minimum = course_ids.map(&:to_i).min
      maximum = course_ids.map(&:to_i).max
      course_ids = (0..maximum).to_a.map(&:to_s)
    end

    # Break up course_ids into smaller groups that Wikipedia's API can handle.
    data = Utils.chunk_requests(course_ids) { |c| Wiki.get_course_info c }
    import_courses(raw_ids, data)
  end

  def self.import_courses(raw_ids, data)
    courses = []
    participants = {}
    listed_ids = raw_ids.values.flatten

    # Delist courses that have been deleted
    Course.where(listed: true).each do |c|
      c.delist unless listed_ids.include?(c.id)
    end

    # Update courses from new data
    data.each do |c|
      c['course']['listed'] = listed_ids.include?(c['course']['id'])
      course = Course.new(id: c['course']['id'])
      course.update(c, false)
      courses.push course
      participants[c['course']['id']] = c['participants']
    end
    options = { on_duplicate_key_update: [:start, :end, :listed] }
    Course.import courses, options

    # Update cohort membership
    Course.transaction do
      raw_ids.each do |ch, ch_courses|
        ch_courses = [ch_courses] unless ch_courses.is_a?(Array)
        cohort = Cohort.find_or_create_by(slug: ch)
        ch_new = ch_courses - cohort.courses.map { |co| co.id.to_s }
        ch_old = cohort.courses.map { |co| co.id.to_s } - ch_courses
        ch_new.each do |co|
          course = Course.find_by_id(co)
          course.cohorts << cohort if course
        end
        ch_old.each do |co|
          course = Course.find_by_id(co)
          course.cohorts.delete(cohort) if course
        end
      end
    end

    import_users participants
    import_assignments participants
  end

  def self.import_users(participants)
    users = []
    participants.each do |_course_id, groups|
      groups.each_with_index do |(r, _p), i|
        users = User.add_users(groups[r], i, nil, false) | users
      end
    end
    User.import users
  end

  def self.import_assignments(participants)
    assignments = []
    ActiveRecord::Base.transaction do
      participants.each do |course_id, group|
        # Update enrollment (add/remove students)
        group_flat = group.map do |role, users|
          users = [users] unless users.instance_of? Array
          users.empty? ? nil : users.each { |u| u.merge! 'role' => role }
        end
        group_flat = group_flat.compact.flatten.sort_by { |user| user['id'] }
        user_ids = group_flat.map { |user| user['id'] }
        course = Course.find_by(id: course_id)
        unless user_ids.empty?
          role_index = %w(student instructor online_volunteer
                          campus_volunteer wiki_ed_staff)
          # Set up structures for operating on
          existing_flat = course.courses_users.map do |cu|
            { 'id' => cu.user_id.to_s, 'role' => role_index[cu.role] }
          end
          new_flat = group_flat.map do |u|
            { 'id' => u['id'], 'role' => u['role'] }
          end
          # Unenroll users who have been removed
          unless course.users.empty?
            unenrolled = (existing_flat - new_flat).map { |u| u['id'] }
            course.users.delete(course.users.find(unenrolled))
          end
          # Enroll new users
          enrolled = (new_flat - existing_flat).map { |u| u['id'] }
          if enrolled.count > 0
            group_flat.each do |u|
              next() unless enrolled.include? u['id']
              role = role_index.index(u['role'])
              role = 4 if u['username'].include? '(Wiki Ed)'
              CoursesUsers.new(user_id: u['id'], course: course, role: role).save
            end
          end
        end

        # Add assigned articles
        group_flat.each do |user|
          next unless user.key? 'article'
          is_array = user['article'].is_a?(Array)
          user['article'] = [user['article']] unless is_array
          user['article'].each do |article|
            assignment = {
              'user_id' => user['id'],
              'course_id' => course_id,
              'article_title' => article['title'],
              'article_id' => nil
            }
            article = Article.find_by(title: article['title'])
            assignment['article_id'] = article.nil? ? nil : article.id
            assignments.push Assignment.new(assignment)
          end
        end
      end
    end
    Assignment.import assignments
  end

  def self.update_all_caches
    Course.transaction do
      Course.current.each(&:update_cache)
    end
  end
end
