class User < ActiveRecord::Base
  has_and_belongs_to_many :courses
  # has_many :assignments
  has_many :revisions
  has_many :articles, -> { uniq }, through: :revisions

  ####################
  # Instance methods #
  ####################
  def contribution_url
    "https://en.wikipedia.org/wiki/Special:Contributions/#{self.wiki_id}"
  end

  # Cache methods
  def character_sum
    # Do not consider revisions with negative byte changes
    read_attribute(:character_sum) || revisions.where('characters > 0').sum(:characters)
  end

  def view_sum
    read_attribute(:view_sum) || articles.sum(:views)
  end

  def course_count
    read_attribute(:course_count) || courses.size
  end

  def revision_count
    read_attribute(:revisions_count) || revisions.size
  end

  def article_count
    read_attribute(:article_count) || article.size
  end

  def update_cache
    # Do not consider revisions with negative byte changes
    self.character_sum = revisions.where('characters > 0').sum(:characters)
    self.view_sum = articles.sum(:views)
    self.revision_count = revisions.size
    self.article_count = articles.size
    self.course_count = courses.size
    self.save
  end


  #################
  # Class methods #
  #################
  def self.update_trained_users
    trained_users = Utils.chunk_requests(User.all) { |block|
      Replica.get_users_completed_training block
    }
    trained_users.each do |u|
      user = User.find_or_create_by(wiki_id: u["rev_user_text"])
      user.trained = true
      user.save
    end
  end

  def self.update_all_caches
    User.all.each do |u|
      u.update_cache
    end
  end

  # Variable descriptons
  def self.training_def
    "Student editors who have completed the 'training for students' should have made an edit to the feedback page when they finished. If any student editors went through the training but did not complete the feedback step, they can return to the end of the training here: https://en.wikipedia.org/wiki/Wikipedia:Training/For_students/Training_complete"
  end

  def self.character_def
    "The total amount of content a user has added to Wikipedia articles, calculated by adding up the size increases for every edit the user made that added net content. This offers a rough indication of how much they contributed to Wikipedia. This number may be misleadingly large if the user added the same content multiple time after someone else removed it, or if the user accidentally removed existing content and then restored it."
  end
end

# Roles:
#   Instructors
#   Advisors
#   Student
