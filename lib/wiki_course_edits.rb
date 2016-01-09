require "#{Rails.root}/lib/wiki_edits"

#= Class for making wiki edits for a particular course
class WikiCourseEdits
  def initialize(action:, course:, current_user:, **opts)
    @course = course
    @current_user = current_user
    send(action, opts)
  end

  def update_course(delete: false)
    require './lib/wiki_course_output'

    return unless @current_user && @course.submitted && @course.slug

    if delete == true
      wiki_text = ''
    else
      wiki_text = WikiCourseOutput.translate_course(@course)
    end

    course_prefix = ENV['course_prefix']
    wiki_title = "#{course_prefix}/#{@course.slug}"

    dashboard_url = ENV['dashboard_url']
    summary = "Updating course from #{dashboard_url}"

    # Post the update
    response = WikiEdits.post_whole_page(@current_user, wiki_title, wiki_text, summary)

    # If it hit the spam blacklist, replace the offending links and try again.
    if response['edit']
      bad_links = response['edit']['spamblacklist']
      return response if bad_links.nil?
      bad_links = bad_links.split('|')
      safe_wiki_text = WikiCourseOutput
                       .substitute_bad_links(wiki_text, bad_links)
      WikiEdits.post_whole_page(@current_user, wiki_title, safe_wiki_text, summary)
    end
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

  def enroll_in_course(*)
    # Add a template to the user page
    course_title = @course.wiki_title
    template = "{{student editor|course = [[#{course_title}]] }}\n"
    user_page = "User:#{@current_user.wiki_id}"
    summary = "I am enrolled in [[#{course_title}]]."
    WikiEdits.add_to_page_top(user_page, @current_user, template, summary)

    # Pre-create the user's sandbox
    # TODO: Do this more selectively, replacing the default template if
    # it is present.
    sandbox = user_page + '/sandbox'
    sandbox_template = "{{#{ENV['dashboard_url']} sandbox}}"
    sandbox_summary = "adding {{#{ENV['dashboard_url']} sandbox}}"
    WikiEdits.add_to_page_top(sandbox, @current_user, sandbox_template, sandbox_summary)
  end
end
