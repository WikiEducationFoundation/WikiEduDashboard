# frozen_string_literal: true

require "#{Rails.root}/lib/wiki_edits"
require "#{Rails.root}/lib/wiki_course_output"
require "#{Rails.root}/lib/wiki_assignment_output"
require "#{Rails.root}/lib/wikitext"
require "#{Rails.root}/lib/wiki_output_templates"

#= Class for making wiki edits for a particular course
class WikiCourseEdits
  include WikiOutputTemplates

  def initialize(action:, course:, current_user:, **opts)
    return unless course.wiki_edits_enabled?
    return if course.private # Never make edits for private courses.
    @course = course
    # Edits can only be made to the course's home wiki through WikiCourseEdits
    @home_wiki = course.home_wiki
    return unless @home_wiki.edits_enabled?
    @wiki_editor = WikiEdits.new(@home_wiki)
    @dashboard_url = ENV['dashboard_url']
    @current_user = current_user
    template_file_path = "config/templates/#{@dashboard_url}_#{@home_wiki.language}.yml"
    @templates = YAML.load_file(Rails.root + template_file_path)
    send(action, opts)
  end

  # Updates the on-wiki version of a course to reflect the latest
  # set of participants, articles, timeline, and other details.
  # It simply overwrites the previous version.
  def update_course(delete: false)
    return unless @course.wiki_course_page_enabled?
    wiki_text = delete ? '' : WikiCourseOutput.new(@course, @templates).translate_course_to_wikitext

    summary = "Updating course from #{@dashboard_url}"

    # Post the update
    response = @wiki_editor.post_whole_page(@current_user, @course.wiki_title, wiki_text, summary)
    return response unless response['edit']

    # If it hit the spam blacklist, replace the offending links and try again.
    blacklist = response['edit']['spamblacklist']
    return response if blacklist.nil?
    repost_with_sanitized_links(@course.wiki_title, wiki_text, summary, blacklist)
  end

  # Posts to the instructor's userpage, and also makes a public
  # announcement of a newly submitted course at the course announcement page.
  def announce_course(instructor: nil)
    instructor ||= @current_user
    add_course_template_to_instructor_userpage(instructor)
    # Announce the course on the Education Noticeboard or equivalent.
    announce_course_on_announcement_page(instructor)
  end

  # Adds a template to the enrolling student's userpage, and also
  # adds a template to their /sandbox page — creating it if it does not
  # already exist.
  def enroll_in_course(enrolling_user:)
    # Add a template to the user page
    template = "{{#{template_name(@templates, 'editor')}|course = [[#{@course.wiki_title}]]"\
               " | slug = #{@course.slug} }}\n"
    user_page = "User:#{enrolling_user.username}"
    summary = "User has enrolled in [[#{@course.wiki_title}]]."
    @wiki_editor.add_to_page_top(user_page, @current_user, template, summary)

    # Add a template to the user's talk page
    talk_template = "{{#{template_name(@templates, 'user_talk')}|course = [[#{@course.wiki_title}]]"\
                    " | slug = #{@course.slug} }}\n"
    talk_page = "User_talk:#{enrolling_user.username}"
    talk_summary = "adding {{#{template_name(@templates, 'user_talk')}}}"
    @wiki_editor.add_to_page_top(talk_page, @current_user, talk_template, talk_summary)

    # Pre-create the user's sandbox
    # TODO: Do this more selectively, replacing the default template if
    # it is present.
    return unless Features.wiki_ed?
    sandbox = user_page + '/sandbox'
    sandbox_template = "{{#{@dashboard_url} sandbox}}"
    sandbox_summary = "adding {{#{@dashboard_url} sandbox}}"
    @wiki_editor.add_to_page_top(sandbox, @current_user, sandbox_template, sandbox_summary)
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
    return unless @course.assignment_edits_enabled?
    homewiki_assignments_grouped_by_article.each do |article_id, assignments_for_same_article|
      article = Article.find(article_id)
      next unless article.namespace == Article::Namespaces::MAINSPACE
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

  def repost_with_sanitized_links(wiki_title, wiki_text, summary, blacklist)
    bad_links = blacklist.split('|')
    safe_wiki_text = Wikitext.substitute_bad_links(wiki_text, bad_links)
    @wiki_editor.post_whole_page(@current_user, wiki_title, safe_wiki_text, summary)
  end

  def add_course_template_to_instructor_userpage(instructor)
    user_page = "User:#{instructor.username}"
    template = "{{#{template_name(@templates, 'instructor')}|course = [[#{@course.wiki_title}]] }}\n"
    summary = "New course announcement: [[#{@course.wiki_title}]]."

    @wiki_editor.add_to_page_top(user_page, @current_user, template, summary)
  end

  def announce_course_on_announcement_page(instructor)
    announcement_page = ENV['course_announcement_page']
    # rubocop:disable Metrics/LineLength
    announcement = "I have created a new course — #{@course.title} — at #{@dashboard_url}/courses/#{@course.slug}. If you'd like to see more details about my course, check out my course page.--~~~~"
    section_title = "New course announcement: [[#{@course.wiki_title}]] (instructor: [[User:#{instructor.username}]])"
    summary = "New course announcement: [[#{@course.wiki_title}]]."
    # rubocop:enable Metrics/LineLength
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
