class Course < ActiveRecord::Base
  has_many :courses_users, class_name: CoursesUsers
  has_many :users, -> { uniq }, through: :courses_users
  has_many :revisions, -> (course) { where("date >= ?", course.start) }, through: :users

  has_many :articles_courses, class_name: ArticlesCourses
  has_many :articles, -> { uniq }, through: :articles_courses

  # has_many :assignments
  # has_many :assigned_articles, -> { uniq }, through: :assignments, :class_name => "Article"

  ####################
  # Instance methods #
  ####################
  def to_param
    self.slug
  end

  def update_participants(all_participants=[])
    if all_participants.blank?
      Rails.logger.info("Course #{self.title} has no participants")
    elsif all_participants.is_a?(Array)
      all_participants.each do |p|
        add_user(p)
      end
    elsif all_participants.is_a?(Hash)
      add_user(all_participants)
    else
      Rails.logger.warn("Received data of unknown type for participants")
    end
  end

  # Utility for adding participants
  def add_user(user)
    new_user = User.find_or_create_by(id: user["id"])
    new_user.wiki_id = user["username"]
    if(user["article"])
      puts "Found a user with an assignment"
    end
    unless users.include? new_user
      new_user.courses << self
    end
    new_user.save
  end

  def update(data={})
    if data.blank?
      data = Wiki.get_course_info self.id
    end

    # Assumes 'School/Class (Term)' format
    course_info = data["name"].split(/(.*)\/(.*)\s\(([^\)]+)/)
    #self.instructor = data["instructors"]["instructor"]
    self.slug = data["name"].gsub(" ", "_")
    self.school = course_info[1]
    self.title = course_info[2]
    self.term = course_info[3]
    self.start = data["start"].to_date
    self.end = data["end"].to_date
    self.listed = data["listed"]
    if !data["students"].blank?
      self.update_participants data["students"]["student"]
    end
    self.save
  end

  # Cache methods
  def character_sum
    if(!read_attribute(:character_sum))
      update_cache()
    end
    read_attribute(:character_sum)
  end

  def view_sum
    if(!read_attribute(:view_sum))
      update_cache()
    end
    read_attribute(:view_sum)
  end

  def user_count
    read_attribute(:user_count) || users.size
  end

  def revision_count
    read_attribute(:revision_count) || revisions.size
  end

  def article_count
    read_attribute(:article_count) || articles.size
  end

  def update_cache
    # Do not consider revisions with negative byte changes
    self.character_sum = courses_users.sum(:character_sum)
    self.view_sum = articles_courses.sum(:view_count)
    self.user_count = users.size
    self.revision_count = revisions.size
    self.article_count = articles.size
    self.save
  end

  #################
  # Class methods #
  #################
  def self.update_all_courses(initial=false)
    listed_ids = Wiki.get_course_list
    course_ids = listed_ids | Course.all.pluck(:id).map(&:to_s)
    minimum = course_ids.map(&:to_i).min
    maximum = course_ids.map(&:to_i).max
    max_plus = maximum + 2
    if(initial)
      course_ids = (0..max_plus).to_a.map(&:to_s)
    else
      course_ids = course_ids | (maximum..max_plus).to_a.map(&:to_s)
    end

    courses = Utils.chunk_requests(course_ids) {|c| Wiki.get_course_info c}
    courses.each do |c|
      c["listed"] = listed_ids.include?(c["id"])
      course = Course.find_or_create_by(id: c["id"])
      course.update c
    end
  end

  def self.update_all_caches
    Course.all.each do |c|
      c.update_cache
    end
  end

  # Variable descriptons
  def self.character_def
    "The gross sum of characters added and removed by the course's students during the course term"
  end

  def self.view_def
    "The sum of all views to articles edited by students in this course during the course term"
  end
end
