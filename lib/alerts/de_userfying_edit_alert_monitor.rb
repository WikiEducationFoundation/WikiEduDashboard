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
    student_edits = edits_made_by_students(edits, current_students)
    student_edits.each do |edit|
      article = Article.find_by(mw_page_id: edit['pageid'])
      user = User.find_by(username: edit['user'])
      course_id = ArticlesCourses
                  .where(article_id: article.id)
                  .joins(course: [:users])
                  .find_by(users: { id: user.id })
                  .course_id
      create_alert(user.id, course_id, article.id, edit['revid'])
    end
  end

  def edits
    api = WikiApi.new @wiki
    query_params = {
      list: 'recentchanges',
      rcprop: 'title|ids|flags|user|tags|loginfo',
      rctag: 'de-userfying',
      rcshow: '!bot'
    }
    res = api.query(query_params)
    res.data['recentchanges'].map { |change| change.slice('user', 'revid', 'pageid', 'logparams') }
  end

  # Those enrolled in at least one course. Multiple enrolled are counted only once.
  def current_students
    CoursesUsers
      .select(:user_id, 'users.username')
      .joins(:user)
      .where(role: CoursesUsers::Roles::STUDENT_ROLE)
      .distinct(:user_id)
  end

  def edits_made_by_students(edits, students)
    usernames = students.map(&:username)
    edits.filter { |edit| usernames.include?(edit['user']) }
  end

  def create_alert(user_id, course_id, article_id, revision_id)
    return if alert_already_exists?(course_id, article_id, revision_id)
    alert = Alert.create!(type: 'DeUserfyingAlert',
                          user_id: user_id,
                          course_id: course_id,
                          article_id: article_id,
                          revision_id: revision_id)
    alert.email_content_expert
  end

  def alert_already_exists?(course_id, article_id, revision_id)
    Alert.exists?(type: 'DeUserfyingAlert',
                  course_id: course_id,
                  article_id: article_id,
                  revision_id: revision_id)
  end
end
