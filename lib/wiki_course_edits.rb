require "#{Rails.root}/lib/wiki_edits"

#= Class for making wiki edits for a particular course
class WikiCourseEdits
  def initialize(action:, course:, current_user:, **opts)
    @course = course
    @current_user = current_user
    send(action, opts)
  end

  # This method both posts to the instructor's userpage and also makes a public
  # announcement of a newly submitted course at the course announcement page.
  def announce_course(instructor: nil)
    instructor ||= @current_user
    course_title = @course.wiki_title
    user_page = "User:#{instructor.wiki_id}"
    template = "{{course instructor|course = [[#{course_title}]] }}\n"
    summary = "New course announcement: [[#{course_title}]]."

    # Add template to userpage to indicate instructor role.
    WikiEdits.add_to_page_top(user_page, @current_user, template, summary)

    # Announce the course on the Education Noticeboard or equivalent.
    announcement_page = ENV['course_announcement_page']
    dashboard_url = ENV['dashboard_url']
    # rubocop:disable Metrics/LineLength
    announcement = "I have created a new course — #{@course.title} — at #{dashboard_url}/courses/#{@course.slug}. If you'd like to see more details about my course, check out my course page.--~~~~"
    section_title = "New course announcement: [[#{course_title}]] (instructor: [[User:#{instructor.wiki_id}]])"
    # rubocop:enable Metrics/LineLength
    message = { sectiontitle: section_title,
                text: announcement,
                summary: summary }

    WikiEdits.add_new_section(@current_user, announcement_page, message)
  end
end
