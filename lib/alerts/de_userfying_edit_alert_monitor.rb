# frozen_string_literal: true

# This class identifies articles that have been moved from
# their use space by users
# Tag: de-userfying
# Cf. https://en.wikipedia.org/wiki/MediaWiki:Tag-de-userfying
class DeUserfyingEditAlertMonitor
  def self.create_alerts_for_deuserfying_edits
    new.create_alerts
  end

  def initialize
    @wiki = Wiki.find_by(language: 'en', project: 'wikipedia')
  end

  def create_alerts
    edits_by_users = edits_made_by_users(edits, current_users)

    edits_by_users.each do |edit|
      article = article_by_mw_page_id(edit['pageid'])
      user = User.find_by(username: edit['user'])
      course_ids = courses_for_user(user.id)
      details = { logid: edit['logid'], timestamp: edit['timestamp'], title: edit['title'] }
      course_ids.each do |course_id|
        create_alert(user.id, course_id, article&.id, edit['revid'], details)
      end
    end
  end

  # Query:
  # https://en.wikipedia.org/w/api.php?action=query&list=recentchanges&rcprop=title|ids|flags|user|tags|loginfo|timestamp&rctag=de-userfying&rclimit=100&rcshow=!bot
  # Will fetch last 100 edits (parameter rclimit)
  # Cf. https://www.mediawiki.org/wiki/API:RecentChanges
  def edits
    api = WikiApi.new @wiki
    query_params = {
      list: 'recentchanges',
      rcprop: 'title|ids|flags|user|tags|loginfo|timestamp',
      rclimit: '100',
      rctag: 'de-userfying',
      rcshow: '!bot'
    }
    res = api.query(query_params)
    res.data['recentchanges']
       .map do |change|
      change.slice('user', 'revid', 'pageid', 'logparams', 'logid', 'timestamp', 'title')
    end
  end

  # Those enrolled in at least one course. Multiple enrolled are counted only once.
  def current_users
    CoursesUsers
      .select(:user_id, 'users.username')
      .joins(:user)
      .where(role: [CoursesUsers::Roles::STUDENT_ROLE, CoursesUsers::Roles::INSTRUCTOR_ROLE])
      .distinct(:user_id)
  end

  def edits_made_by_users(edits, users)
    usernames = Set.new(users.map(&:username))
    edits.filter { |edit| usernames.include?(edit['user']) }
  end

  def create_alert(user_id, course_id, article_id, revision_id, details)
    return if alert_already_exists?(course_id, article_id, revision_id)
    alert = Alert.create!(type: 'DeUserfyingAlert',
                          user_id:,
                          course_id:,
                          article_id:,
                          revision_id:,
                          details:)
    alert.email_content_expert
  end

  def alert_already_exists?(course_id, article_id, revision_id)
    Alert.exists?(type: 'DeUserfyingAlert',
                  course_id:,
                  article_id:,
                  revision_id:)
  end

  def courses_for_user(user_id)
    CoursesUsers
      .joins(:user)
      .where(user_id:)
      .pluck(:course_id)
  end

  def article_by_mw_page_id(mw_page_id)
    wiki_id = @wiki.id
    unless Article.exists?(wiki_id:, mw_page_id:)
      ArticleImporter.new(@wiki).import_articles([mw_page_id])
    end
    Article.find_by(wiki_id:, mw_page_id:)
  end
end
