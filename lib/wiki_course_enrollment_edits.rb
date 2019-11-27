# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/wiki_output_templates"
require_dependency "#{Rails.root}/lib/wiki_edits"
require_dependency "#{Rails.root}/lib/wiki_api"
require_dependency "#{Rails.root}/lib/wiki_userpage_output"

#= Class for making wiki enrollment edits for a particular course
class WikiCourseEnrollmentEdits
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
    send(action, opts)
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

  # Removes existing template from the disenrolling student's userpage, and also
  # removes existing template from their talk page
  def disenroll_from_course(disenrolling_user:)
    @disenrolling_user = disenrolling_user
    @generator = WikiUserpageOutput.new(@course)

    remove_template_from_user_page
    remove_template_from_user_talk_page
  end

  private

  def validate(action)
    yield unless course_edits_allowed?

    # action-specific checks
    case action
    when :enroll_in_course, :disenroll_from_course
      yield unless @course.enrollment_edits_enabled?
    end
  end

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

    # Never double-post the sandbox template
    initial_page_content = @wiki_api.get_page_content(sandbox)
    return if initial_page_content.include?(sandbox_template)

    sandbox_summary = "adding {{#{@dashboard_url} sandbox}}"
    new_line_template = sandbox_template + "\n"
    @wiki_editor.add_to_page_top(sandbox, @current_user, new_line_template, sandbox_summary)
  end

  def remove_template_from_user_page
    template = @generator.enrollment_template
    user_page = "User:#{@disenrolling_user.username}"
    summary = @generator.disenrollment_summary
    remove_content_from_article(title: user_page, content: template, summary: summary)
  end

  def remove_template_from_user_talk_page
    talk_template = @generator.enrollment_talk_template
    talk_page = "User_talk:#{@disenrolling_user.username}"
    talk_summary = "removing {{#{template_name(@templates, 'user_talk')}}}"
    remove_content_from_article(title: talk_page, content: talk_template, summary: talk_summary)
  end

  def remove_content_from_article(title:, content:, summary:)
    initial_page_content = @wiki_api.get_page_content(title)
    # This indicates an API failure, which may happen because of rate-limiting.
    # A nonexistent page will return empty string instead of nil.
    return if initial_page_content.nil?

    page_content = initial_page_content.dup.force_encoding('utf-8')
    # Return unless content already exists on page.
    return unless page_content.include? content

    # Remove content
    page_content.gsub!(/#{Regexp.quote(content)}/, '')

    @wiki_editor.post_whole_page(@current_user, title, page_content, summary)
  end
end
