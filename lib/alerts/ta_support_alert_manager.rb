# frozen_string_literal: true

class NoTaSupportAlertManager
    def initialize(tagged_courses)
      @tagged_courses = tagged_courses
    end

    def get_course_instructors(course_id)
      CoursesUsers.where(course_id: course_id, role: CoursesUsers::Roles::INSTRUCTOR_ROLE).pluck(:user_id)
    end

    def create_alerts
      @tagged_courses.each do |course|
        instructors = get_course_instructors(course.course_id)
        next unless within_no_ta_alert_period?(course.created_at)
        next unless instructors.size > 1

        next if Alert.exists?(course_id: course.course_id, type: 'NoTaEnrolledAlert')
        alert = Alert.create(type: 'NoTaEnrolledAlert', course_id: course.course_id)
        alert.send_email
      end
    end
  
    private
  
    # Only create an alert if has been at least MIN_DAYS (7days)
    NO_TA_ALERT_MIN_DAYS = 7
    def within_no_ta_alert_period?(date)
      return false unless date < NO_TA_ALERT_MIN_DAYS.days.ago
      true
    end
  end
  
# @tagged_courses
# *************************** 15. row ***************************
#         id: 122
#  course_id: 10109
#        tag: ta_support
#        key: NULL
# created_at: 2024-03-01 10:27:54
# updated_at: 2024-03-01 10:27:54
# *************************** 11. row ***************************
#         id: 118
#  course_id: 10108
#        tag: ta_support
#        key: NULL
# created_at: 2024-02-29 11:50:35
# updated_at: 2024-02-29 11:50:35

# courses_users
# *************************** 95. row ***************************
#                     id: 157
#             created_at: 2024-02-29 11:50:35
#             updated_at: 2024-02-29 11:50:35
#              course_id: 10108
#                user_id: 44
#       character_sum_ms: 0
#       character_sum_us: 0
#         revision_count: 0
# assigned_article_title: NULL
#                   role: 1
#       recent_revisions: 0
#    character_sum_draft: 0
#              real_name: Ujjwal Pathak
#       role_description: Teaching Assistant
#          total_uploads: NULL
#       references_count: 0
# *************************** 96. row ***************************
#                     id: 158
#             created_at: 2024-03-01 10:27:54
#             updated_at: 2024-03-01 10:27:54
#              course_id: 10109
#                user_id: 43
#       character_sum_ms: 0
#       character_sum_us: 0
#         revision_count: 0
# assigned_article_title: NULL
#                   role: 1
#       recent_revisions: 0
#    character_sum_draft: 0
#              real_name: Ujjwal Pathak
#       role_description: Teaching Assistant
#          total_uploads: NULL
#       references_count: 0
