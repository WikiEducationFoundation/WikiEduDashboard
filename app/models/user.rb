class User < ActiveRecord::Base
  has_many :courses_users, class_name: CoursesUsers
  has_many :courses, -> { uniq }, through: :courses_users
  has_many :revisions
  has_many :articles, -> { uniq }, through: :revisions

  enum role: [ :student, :instructor, :online_volunteer, :campus_volunteer, :wiki_ed_staff ]


  ####################
  # Instance methods #
  ####################
  def contribution_url
    "https://en.wikipedia.org/wiki/Special:Contributions/#{self.wiki_id}"
  end



  #################
  # Cache methods #
  #################
  def view_sum
    read_attribute(:view_sum) || articles.map {|a| a.views}.inject(:+) || 0
  end


  def course_count
    read_attribute(:course_count) || courses.size
  end


  def revision_count(after_date=nil)
    if(after_date.nil?)
      read_attribute(:revision_count) || revisions.size
    else
      revisions.after_date(after_date).size
    end
  end


  def article_count
    read_attribute(:article_count) || article.size
  end


  def update_cache
    # Do not consider revisions with negative byte changes
    self.character_sum = Revision.joins(:article).where(articles: {namespace: 0}).where(user_id: self.id).where('characters >= 0').sum(:characters) || 0
    self.view_sum = articles.map {|a| a.views || 0}.inject(:+) || 0
    self.revision_count = revisions.size
    self.article_count = articles.size
    self.course_count = courses.size
    self.save
  end



  #################
  # Class methods #
  #################
  def self.add_users(data, role, course, save=true)
    if data.is_a?(Array)
      data.map do |p|
        add_user(p, role, course, save)
      end
    elsif data.is_a?(Hash)
      [add_user(data, role, course, save)]
    else
      Rails.logger.warn("Received data of unknown type for participants")
    end
  end


  def self.add_user(user, role, course, save=true)
    new_user = save ? User.find_or_create_by(id: user["id"]) : User.new(id: user["id"])
    new_user.wiki_id = user["username"]
    new_user.role = (user["username"].include? "(Wiki Ed)") ? 4 : role
    if(user["article"])
      Rails.logger.info "Found user #{user["username"]} with an assignment \"#{user["article"]}\""
    end
    if save
      unless course.users.include? new_user
        new_user.courses << course
      end
      new_user.save
    end
    new_user
  end


  def self.update_trained_users
    trained_users = Utils.chunk_requests(User.all) { |block|
      Replica.get_users_completed_training block
    }
    wiki_ids = trained_users.map{|u| u["rev_user_text"]}
    User.where(wiki_id: wiki_ids).update_all(trained: true)
  end


  def self.update_all_caches
    User.transaction do
      User.all.each do |u|
        u.update_cache
      end
    end
  end


end
