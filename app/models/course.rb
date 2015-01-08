class Course < ActiveRecord::Base
  has_and_belongs_to_many :users
  has_many :revisions, -> (course) { where("date >= ?", course.start) }, through: :users
  has_many :articles, -> { uniq }, through: :revisions
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
      all_participants = Wiki.get_students_in_course self.id
    end
    unless all_participants.blank?
      all_participants.each do |p|
        user = User.find_or_create_by(wiki_id: p)
        unless user.courses.any? {|course| course.id == self.id }
          user.courses << self
        end
        user.save
      end
    end
  end

  def update(data={})
    if data.blank?
      data = Wiki.get_course_info self.id
    end

    # Assumes 'School/Class (Term)' format
    course_info = data["name"].split(/(.*)\/(.*)\s\(([^\)]+)/)
    self.slug = data["name"].gsub(" ", "_")
    self.school = course_info[1]
    self.title = course_info[2]
    self.term = course_info[3]
    self.start = data["start"].to_date
    self.end = data["end"].to_date
    if !data["students"].blank? && data["students"]["username"].kind_of?(Array)
      self.update_participants data["students"]["username"]
    end
    self.save
  end

  # Cache methods
  def character_sum
    # Do not consider revisions with negative byte changes
    read_attribute(:character_sum) || revisions.where('characters > 0').map {|r| r.characters}.inject(:+) || 0
  end

  def view_sum
    read_attribute(:view_sum) || articles.map {|a| a.views}.inject(:+) || 0
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
    self.character_sum = revisions.where('characters > 0').map {|r| r.characters}.inject(:+) || 0
    self.view_sum = articles.map {|a| a.views}.inject(:+) || 0
    self.user_count = users.size
    self.revision_count = revisions.size
    self.article_count = articles.size
    self.save
  end

  #################
  # Class methods #
  #################
  def self.update_all_courses
    courses = Utils.chunk_requests(Wiki.get_course_list) {|block| Wiki.get_course_info block}
    courses.each do |c|
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
