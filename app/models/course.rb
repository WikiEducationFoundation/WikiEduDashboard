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


  def update(data={})
    if data.blank?
      data = Wiki.get_course_info self.id
    end
    self.attributes = data["course"]
    data["participants"].each_with_index do |(r, p), i|
      User.add_users(data["participants"][r], i, self)
    end
    self.save
  end



  #################
  # Cache methods #
  #################
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
    read_attribute(:user_count) || users.student.size
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
    self.user_count = users.student.size
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
      c["course"]["listed"] = listed_ids.include?(c["course"]["id"])
      course = Course.find_or_create_by(id: c["course"]["id"])
      course.update c
    end
  end


  def self.update_all_caches
    Course.all.each do |c|
      c.update_cache
    end
  end


end
