# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/wiki_edits"
require_dependency "#{Rails.root}/lib/wiki_course_output"
require_dependency "#{Rails.root}/lib/wiki_assignment_output"
require_dependency "#{Rails.root}/lib/wiki_userpage_output"
require_dependency "#{Rails.root}/lib/wikitext"
require_dependency "#{Rails.root}/lib/wiki_output_templates"
require_dependency "#{Rails.root}/lib/wiki_api"
require_dependency "#{Rails.root}/app/services/add_sandbox_template"

#= Class for making wiki edits for a particular course
class WikiCourseEdits
  include WikiOutputTemplates

  def initialize(action:, course:, current_user:, **opts)
    @course = course
    @home_wiki = course.home_wiki
    validate(action) { return }

    @wiki_editor = WikiEdits.new(@home_wiki)
    @wiki_api = WikiApi.new(@home_wiki)
    @dashboard_url = ENV['dashboard_url']
    @current_user = current_user
    @templates = @home_wiki.edit_templates
    send(action, **opts)
  end

  # Updates the on-wiki version of a course to reflect the latest
  # set of participants, articles, timeline, and other details.
  # It simply overwrites the previous version.
  def update_course(delete: false)
    wiki_text = delete ? '' : WikiCourseOutput.new(@course).translate_course_to_wikitext

    summary = "Updating course from #{@dashboard_url}"

    # Post the update
    response = @wiki_editor.post_whole_page(@current_user, @course.wiki_title, wiki_text, summary)
    return response unless response['edit']

    # If it hit the spam blocklist, replace the offending links and try again.
    spamlist = response['edit']['spamblacklist']
    return response if spamlist.nil?
    repost_with_sanitized_links(@course.wiki_title, wiki_text, summary, spamlist)
  end

  # Posts to the instructor's userpage, and also makes a public
  # announcement of a newly submitted course at the course announcement page.
  def announce_course(instructor: nil)
    return unless @course.wiki_title # Don't post for courses that lack a wiki course page

    instructor ||= @current_user
    add_course_template_to_instructor_userpage(instructor)
    # Announce the course on the Education Noticeboard or equivalent.
    announce_course_on_announcement_page(instructor)
  end

  # Adds a template to the enrolling student's userpage, and also
  # adds a template to their /sandbox page — creating it if it does not
  # already exist.
  def enroll_in_course(enrolling_user:)
    @enrolling_user = enrolling_user
    @generator = WikiUserpageOutput.new(@course)

    add_template_to_user_page
    add_template_to_user_talk_page

    # Pre-create the user's sandbox
    return unless Features.wiki_ed?
    add_template_to_sandbox
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
    homewiki_assignments_grouped_by_article.each do |article_id, assignments_for_same_article|
      article = Article.find(article_id)
      next unless article.namespace == Article::Namespaces::MAINSPACE
      next if article.deleted
      update_assignments_for_article(title: article.title,
                                     assignments_for_same_article: assignments_for_same_article)
    end
  end

  def remove_assignment(assignment:)
    # This is only relevant if the removed assignment is on the home wiki.
    return unless assignment.wiki_id == @home_wiki.id

    article_title = assignment.article_title
    other_assignments_for_same_course_and_title = assignment.sibling_assignments
                                                            .where.not(article_id: nil)

    update_assignments_for_article(
      title: article_title,
      assignments_for_same_article: other_assignments_for_same_course_and_title
    )
  end

  private

  # rubocop:disable Metrics/CyclomaticComplexity
  def validate(action)
    yield unless course_edits_allowed?

    # action-specific checks
    case action
    when :update_course
      yield unless @course.wiki_course_page_enabled?
    when :update_assignments, :remove_assignment
      yield unless @course.assignment_edits_enabled?
    when :enroll_in_course
      yield unless @course.enrollment_edits_enabled?
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity

  def course_edits_allowed?
    return false unless @course.wiki_edits_enabled?
    # Never make edits for private courses.
    return false if @course.private
    # Edits can only be made to the course's home wiki through WikiCourseEdits
    return false unless @home_wiki.edits_enabled?
    true
  end

  def add_template_to_user_page
    template = @generator.enrollment_template
    user_page = "User:#{@enrolling_user.username}"

    # Never double-post the enrollment template
    initial_page_content = @wiki_api.get_page_content(user_page)
    return if initial_page_content.include?(template)

    summary = @generator.enrollment_summary
    new_line_template = template + "\n"
    @wiki_editor.add_to_page_top(user_page, @current_user, new_line_template, summary)
  end

  def add_template_to_user_talk_page
    talk_template = @generator.enrollment_talk_template
    talk_page = "User_talk:#{@enrolling_user.username}"

    # Never double-post the talk template
    initial_page_content = @wiki_api.get_page_content(talk_page)
    return if initial_page_content.include?(talk_template)

    talk_summary = "adding {{#{template_name(@templates, 'user_talk')}}}"
    new_line_template = talk_template + "\n"
    @wiki_editor.add_to_page_top(talk_page, @current_user, new_line_template, talk_summary)
  end

  def add_template_to_sandbox
    sandbox_template = @generator.sandbox_template(@dashboard_url)
    sandbox = "User:#{@enrolling_user.username}/sandbox"

    AddSandboxTemplate.new(home_wiki: @home_wiki, sandbox: sandbox,
                           sandbox_template: sandbox_template, current_user: @current_user)
  end

  def repost_with_sanitized_links(wiki_title, wiki_text, summary, spamlist)
    bad_links = spamlist.split('|')
    safe_wiki_text = Wikitext.substitute_bad_links(wiki_text, bad_links)
    @wiki_editor.post_whole_page(@current_user, wiki_title, safe_wiki_text, summary)
  end

  def add_course_template_to_instructor_userpage(instructor)
    user_page = "User:#{instructor.username}"
    template = "{{#{template_name(@templates, 'instructor')}"\
               " | course = [[#{@course.wiki_title}]] }}\n"
    summary = "New course announcement: [[#{@course.wiki_title}]]."

    @wiki_editor.add_to_page_top(user_page, @current_user, template, summary)
  end

  def announce_course_on_announcement_page(instructor)
    announcement_page = ENV['course_announcement_page']
    # rubocop:disable Layout/LineLength
    announcement = "I have created a new course — #{@course.title} — at #{@dashboard_url}/courses/#{@course.slug}. If you'd like to see more details about my course, check out my course page.--~~~~"
    section_title = "New course announcement: [[#{@course.wiki_title}]] (instructor: [[User:#{instructor.username}]])"
    summary = "New course announcement: [[#{@course.wiki_title}]]."
    # rubocop:enable Layout/LineLength
    message = { sectiontitle: section_title,
                text: announcement,
                summary: summary }

    @wiki_editor.add_new_section(@current_user, announcement_page, message)
  end

  def homewiki_assignments_grouped_by_article
    # Only do on-wiki updates for articles that are on the course's home wiki
    # and that are not 'available articles' with no assigned user.
    @course.assignments.where(wiki: @home_wiki)
           .where.not(article_id: nil)
           .where.not(user_id: nil)
           .group_by(&:article_id)
  end

  def update_assignments_for_article(title:, assignments_for_same_article:)
    return if WikiApi.new(@home_wiki).redirect?(title)

    # MediaWiki will automatically handle i18n of the namespace
    talk_title = "Talk:#{title.tr(' ', '_')}"

    page_content = WikiAssignmentOutput.wikitext(course: @course,
                                                 title: title,
                                                 talk_title: talk_title,
                                                 assignments: assignments_for_same_article,
                                                 templates: @templates)

    return if page_content.nil?
    summary = "Update [[#{@course.wiki_title}|#{@course.title}]] assignment details"
    @wiki_editor.post_whole_page(@current_user, talk_title, page_content, summary)
  end
end
