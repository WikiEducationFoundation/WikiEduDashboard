# frozen_string_literal: true

class ContinuedCourseActivityAlertManager
  def initialize(courses)
    @courses = courses
  end

  def create_alerts
    @courses.each do |course|
      next if Alert.exists?(course_id: course.id,
                            type: 'ContinuedCourseActivityAlert',
                            resolved: false)

      next if course.students.empty?

      next unless significant_activity_after_course_end?(course)

      alert = Alert.create(type: 'ContinuedCourseActivityAlert', course_id: course.id)
      alert.email_content_expert
    end
  end

  private

  MINIMUM_REVISIONS_AFTER_COURSE_END = 20
  def significant_activity_after_course_end?(course)
    total_revisions = course.wikis.sum do |wiki|
      count_revisions_for_wiki(course, wiki)
    end
    total_revisions > MINIMUM_REVISIONS_AFTER_COURSE_END
  end

  def count_revisions_for_wiki(course, wiki)
    # 50 is the max users for query
    course.students.pluck(:username).in_groups_of(40, false).sum do |usernames|
      response = WikiApi.new(wiki).query(query(course, usernames))
      response.data['usercontribs'].count
    end
  end

  def query(course, users)
    {
      list: 'usercontribs',
      ucuser: users,
      ucnamespace: Article::Namespaces::MAINSPACE,
      ucend: course.end.end_of_day.strftime('%Y%m%d%H%M%S'),
      uclimit: MINIMUM_REVISIONS_AFTER_COURSE_END + 1
    }
  end
end
