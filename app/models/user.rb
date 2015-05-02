#= User model
class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :rememberable, :omniauthable, omniauth_providers: [:mediawiki]

  has_many :courses_users, class_name: CoursesUsers
  has_many :courses, -> { uniq }, through: :courses_users
  has_many :revisions
  has_many :articles, -> { uniq }, through: :revisions
  has_many :assignments

  scope :admin, -> { where(permissions: 1) }
  scope :current, -> { joins(:courses).merge(Course.current).uniq }
  scope :role, lambda { |role|
    index = %w(student instructor online_volunteer
               campus_volunteer wiki_ed_staff)
    joins(:courses_users).where(courses_users: { role: index.index(role) })
  }

  ####################
  # Instance methods #
  ####################
  def contribution_url
    language = Figaro.env.wiki_language
    # rubocop:disable Metrics/LineLength
    "https://#{language}.wikipedia.org/wiki/Special:Contributions/#{wiki_id}"
    # rubocop:enable Metrics/LineLength
  end

  def is_admin
    permissions == 1
  end

  def is_instructor(course)
    course.users.role('instructor').include? self
  end

  #################
  # Cache methods #
  #################
  def view_sum
    self[:view_sum] || articles.map(&:views).inject(:+) || 0
  end

  def course_count
    self[:course_count] || courses.size
  end

  def revision_count(after_date=nil)
    if after_date.nil?
      self[:revision_count] || revisions.size
    else
      revisions.after_date(after_date).size
    end
  end

  def article_count
    self[:article_count] || article.size
  end

  def update_cache
    # Do not consider revisions with negative byte changes
    self.character_sum = Revision.joins(:article)
      .where(articles: { namespace: 0 })
      .where(user_id: id)
      .where('characters >= 0')
      .sum(:characters) || 0
    self.view_sum = articles.map { |a| a.views || 0 }.inject(:+) || 0
    self.revision_count = revisions.size
    self.article_count = articles.size
    self.course_count = courses.size
    save
  end

  #################
  # Class methods #
  #################
  def self.from_omniauth(auth)
    user = User.find_by(wiki_id: auth.info.name)
    if user.nil?
      user = new_from_omniauth(auth)
    else
      user.update(
        global_id: auth.uid,
        wiki_token: auth.credentials.token,
        wiki_secret: auth.credentials.secret
      )
    end
    user
  end

  def self.new_from_omniauth(auth)
    id = Replica.get_user_id(auth.info.name)
    user = User.create(
      id: id,
      wiki_id: auth.info.name,
      global_id: auth.uid,
      wiki_token: auth.credentials.token,
      wiki_secret: auth.credentials.secret
    )
    user
  end


  def self.add_users(data, role, course, save=true)
    if data.is_a?(Array)
      data.map do |p|
        add_user(p, role, course, save)
      end
    elsif data.is_a?(Hash)
      [add_user(data, role, course, save)]
    else
      Rails.logger.warn('Received data of unknown type for participants')
    end
  end

  def self.add_user(user, role, course, save=true)
    empty_user = User.new(id: user['id'])
    new_user = save ? User.find_or_create_by(id: user['id']) : empty_user
    new_user.wiki_id = user['username']
    if save
      role_index = %w(student instructor online_volunteer
                      campus_volunteer wiki_ed_staff)
      has_user = course.users.role(role_index[role]).include? new_user
      unless has_user
        role = (user['username'].include? '(Wiki Ed)') ? 4 : role
        CoursesUsers.new(user: new_user, course: course, role: role).save
        new_user.save
      end
    end
    new_user
  end

  def self.update_users(users=nil)
    u_users = Utils.chunk_requests(users || User.all) do |block|
      Replica.get_user_info block
    end

    User.transaction do
      u_users.each do |u|
        begin
          User.find(u['id']).update(u.except('id'))
        rescue ActiveRecord::RecordNotFound
          Rails.logger.warn e
        end
      end
    end
  end

  def self.update_all_caches(users=nil)
    Utils.run_on_all(User, :update_cache, users)
  end
end
