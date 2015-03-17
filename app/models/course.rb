#= Course model
class Course < ActiveRecord::Base
  has_many :courses_users, class_name: CoursesUsers

  has_many :users, -> { uniq }, through: :courses_users
  has_many :students, -> { where(role: 0).uniq }, through: :courses_users
  # rubocop:disable Metrics/LineLength
  has_many :revisions, -> (course) { where('date >= ?', course.start) }, through: :users
  # rubocop:enable Metrics/LineLength

  has_many :articles_courses, class_name: ArticlesCourses
  has_many :articles, -> { uniq }, through: :articles_courses

  has_many :assignments

  scope :cohort, -> (cohort) { where cohort: cohort }

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
    self.cohort = nil
    save
  end

  def update(data={}, save=true)
    if data.blank?
      data = Wiki.get_course_info id
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
    self.view_sum = articles_courses.sum(:view_count)
    self.user_count = users.role('student').size
    self.untrained_count = users.role('student').where(trained: false).size
    self.revision_count = revisions.size
    self.article_count = articles.size
    save
  end

  #################
  # Class methods #
  #################
  def self.update_all_courses(initial=false, raw_ids={})
    raw_ids = Wiki.course_list if raw_ids.empty?
    listed_ids = raw_ids.values.flatten
    course_ids = listed_ids | Course.all.pluck(:id).map(&:to_s)
    _minimum = course_ids.map(&:to_i).min
    maximum = course_ids.map(&:to_i).max
    # See also Wiki.handle_invalid_course_id, which has related logic for
    # handling course ids beyond the maximum found in the cohort lists.
    max_plus = maximum + 2
    if initial
      course_ids = (0..max_plus).to_a.map(&:to_s)
    else
      course_ids |= (maximum..max_plus).to_a.map(&:to_s)
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
      if listed_ids.include?(c['course']['id'])
        c['course']['listed'] = true
        c['course']['cohort'] = raw_ids.reduce(nil) do |out, (ch, ch_courses)|
          ch_courses.include?(c['course']['id']) ? ch : out
        end
      else
        c['course']['listed'] = false
        c['course']['cohort'] = nil
      end
      course = Course.new(id: c['course']['id'])
      course.update(c, false)
      courses.push course
      participants[c['course']['id']] = c['participants']
    end
    options = { on_duplicate_key_update: [:start, :end, :listed, :cohort] }
    Course.import courses, options

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
          # Unenroll users who have been removed
          unless course.users.empty?
            unenrolled = course.users.map { |u| u.id.to_s } - user_ids
            course.users.delete(course.users.find(unenrolled))
          end
          # Enroll new users
          enrolled = user_ids - course.users.map { |u| u.id.to_s }
          if enrolled.count > 0
            role_index = %w(student instructor online_volunteer
                            campus_volunteer wiki_ed_staff)
            roles = Array.new
            group_flat.each do |u|
              if enrolled.include? u['id']
                role = role_index.index(u['role'])
                role = 4 if u['username'].include? '(Wiki Ed)'
                CoursesUsers.new(user_id: u['id'], course: course, role: role).save
              end
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
      Course.all.each(&:update_cache)
    end
  end
end
