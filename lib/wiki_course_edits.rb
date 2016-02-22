require "#{Rails.root}/lib/wiki_edits"
require './lib/wiki_course_output'

#= Class for making wiki edits for a particular course
# TODO: Not multiwiki safe
class WikiCourseEdits
  def initialize(action:, course:, current_user:, **opts)
    return unless course.wiki_edits_enabled?
    @course = course
    @dashboard_url = ENV['dashboard_url']
    @current_user = current_user
    @wiki = course.home_wiki
    send(action, opts)
  end

  # Updates the on-wiki version of a course to reflect the latest
  # set of participants, articles, timeline, and other details.
  # It simply overwrites the previous version.
  def update_course(delete: false)
    return unless @course.submitted && @course.slug

    wiki_text = delete ? '' : WikiCourseOutput.translate_course(@course)

    course_prefix = ENV['course_prefix']
    wiki_title = "#{course_prefix}/#{@course.slug}"

    summary = "Updating course from #{@dashboard_url}"

    # Post the update
    response = WikiEdits.new(@wiki).post_whole_page(@current_user, wiki_title, wiki_text, summary)
    return response unless response['edit']

    # If it hit the spam blacklist, replace the offending links and try again.
    bad_links = response['edit']['spamblacklist']
    return response if bad_links.nil?
    bad_links = bad_links.split('|')
    safe_wiki_text = WikiCourseOutput
                     .substitute_bad_links(wiki_text, bad_links)
    WikiEdits.new(@wiki).post_whole_page(@current_user, wiki_title, safe_wiki_text, summary)
  end

  # Posts to the instructor's userpage, and also makes a public
  # announcement of a newly submitted course at the course announcement page.
  def announce_course(instructor: nil)
    instructor ||= @current_user
    course_title = @course.wiki_title
    user_page = "User:#{instructor.wiki_id}"
    template = "{{course instructor|course = [[#{course_title}]] }}\n"
    summary = "New course announcement: [[#{course_title}]]."

    # Add template to userpage to indicate instructor role.
    WikiEdits.new(@wiki).add_to_page_top(user_page, @current_user, template, summary)

    # Announce the course on the Education Noticeboard or equivalent.
    announcement_page = ENV['course_announcement_page']
    # rubocop:disable Metrics/LineLength
    announcement = "I have created a new course — #{@course.title} — at #{@dashboard_url}/courses/#{@course.slug}. If you'd like to see more details about my course, check out my course page.--~~~~"
    section_title = "New course announcement: [[#{course_title}]] (instructor: [[User:#{instructor.wiki_id}]])"
    # rubocop:enable Metrics/LineLength
    message = { sectiontitle: section_title,
                text: announcement,
                summary: summary }

    WikiEdits.new(@wiki).add_new_section(@current_user, announcement_page, message)
  end

  # Adds a template to the enrolling student's userpage, and also
  # adds a template to their /sandbox page — creating it if it does not
  # already exist.
  def enroll_in_course(**_opts)
    # Add a template to the user page
    course_title = @course.wiki_title
    template = "{{student editor|course = [[#{course_title}]] }}\n"
    user_page = "User:#{@current_user.wiki_id}"
    summary = "I am enrolled in [[#{course_title}]]."
    WikiEdits.new(@wiki).add_to_page_top(user_page, @current_user, template, summary)

    # Pre-create the user's sandbox
    # TODO: Do this more selectively, replacing the default template if
    # it is present.
    sandbox = user_page + '/sandbox'
    sandbox_template = "{{#{@dashboard_url} sandbox}}"
    sandbox_summary = "adding {{#{@dashboard_url} sandbox}}"
    WikiEdits.new(@wiki).add_to_page_top(sandbox, @current_user, sandbox_template, sandbox_summary)
  end

  # Updates the assignment template for every Assignment for the course.
  # Usually, this is done incrementally so that a call to this method will only
  # update the assignments that were changed in the action that triggered it.
  # However, if some previous edits failed, or some assignment templates got
  # removed or edited in the meantime, then this will also result in updates
  # that are not directly related to whatever triggered this update. The idea
  # is to use this for each assignment update to ensure that on-wiki assignment
  # templates remain accurate and up-to-date.
  def update_assignments(*)
    assignments_grouped_by_article_title.each do |title, assignments_for_same_title|
      update_assignments_for_title(
        title: title,
        assignments_for_same_title: assignments_for_same_title)
    end
  end

  def remove_assignment(assignment:)
    article_title = assignment.article_title
    other_assignments_for_same_course_and_title = assignment.sibling_assignments

    update_assignments_for_title(
      title: article_title,
      assignments_for_same_title: other_assignments_for_same_course_and_title)
  end

  private

  def assignments_grouped_by_article_title
    @course.assignments.group_by(&:article_title)
  end

  def update_assignments_for_title(title:, assignments_for_same_title:)
    require './lib/wiki_assignment_output'

    # TODO: i18n of talk namespace
    if title[0..4] == 'Talk:'
      talk_title = title
    else
      talk_title = "Talk:#{title.tr(' ', '_')}"
    end

    course_page = @course.wiki_title
    page_content = WikiAssignmentOutput.new(@wiki)
                   .build_talk_page_update(title,
                                           talk_title,
                                           assignments_for_same_title,
                                           course_page)

    return if page_content.nil?
    course_title = @course.title
    summary = "Update [[#{course_page}|#{course_title}]] assignment details"
    WikiEdits.new(@wiki).post_whole_page(@current_user, talk_title, page_content, summary)
  end
end
