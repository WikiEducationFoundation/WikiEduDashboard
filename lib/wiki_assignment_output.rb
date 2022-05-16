# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/wiki_api"
require_dependency "#{Rails.root}/lib/wiki_output_templates"
#= Class for generating wikitext for updating assignment details on talk pages
class WikiAssignmentOutput
  include WikiOutputTemplates

  def initialize(course, title, talk_title, assignments, templates)
    @course = course
    @course_page = course.wiki_title
    @wiki = course.home_wiki
    @dashboard_url = ENV['dashboard_url']
    @templates = templates
    @assignments = assignments
    @title = title
    @talk_title = talk_title
  end

  ###############
  # Entry point #
  ###############
  def self.wikitext(course:, title:, talk_title:, assignments:, templates:)
    new(course, title, talk_title, assignments, templates).build_talk_page_update
  end

  ################
  # Main routine #
  ################
  def build_talk_page_update
    # If a course changed state so that it has no on-wiki course page, don't post.
    return nil if @course_page.nil?

    initial_page_content = WikiApi.new(@wiki).get_page_content(@talk_title)
    # This indicates an API failure, which may happen because of rate-limiting.
    # A nonexistent page will return empty string instead of nil.
    return nil if initial_page_content.nil?

    # Do not post templates to disambugation pages
    return nil if includes_disambiguation_template?(initial_page_content)

    # We only want to add assignment tags to non-existant talk pages if the
    # article page actually exists, and is not a disambiguation page.
    article_content = WikiApi.new(@wiki).get_page_content(@title)
    return nil if article_content.blank?
    return nil if includes_disambiguation_template?(article_content)

    page_content = build_assignment_page_content(assignments_tag, initial_page_content)
    page_content
  end

  ###################
  # Helper methods #
  ###################
  def assignments_tag
    return '' if @assignments.empty?

    # Make a list of the assignees, role 0
    tag_assigned = build_wikitext_user_list(Assignment::Roles::ASSIGNED_ROLE)
    # Make a list of the reviwers, role 1
    tag_reviewing = build_wikitext_user_list(Assignment::Roles::REVIEWING_ROLE)

    # Build new tag
    # NOTE: If the format of this tag gets changed, then the dashboard may
    # post duplicate tags for the same page, unless we update the way that
    # we check for the presense of existging tags to account for both the new
    # and old formats.
    tag = "{{#{template_name(@templates, 'course_assignment')} | course = #{@course_page}"
    tag += " | assignments = #{tag_assigned}" if tag_assigned.present?
    tag += " | reviewers = #{tag_reviewing}" if tag_reviewing.present?
    tag += " | start_date = #{@course.start.to_date}"
    tag += " | end_date = #{@course.end.to_date}"
    tag += ' }}'

    tag
  end

  # This method creates updated wikitext for an article talk page, for when
  # the set of assigned users for the article for a single course changes.
  # The strategy here is to only update the tag for one course at a time, so
  # that the user who updates the assignments for a course only introduces data
  # for that course. We also want to make as minimal a change as possible, and
  # to make sure that we're not disrupting the format of existing content.
  def build_assignment_page_content(new_tag, page_content)
    page_content = page_content.dup.force_encoding('utf-8')
    # Return if tag already exists on page.
    # However, if the tag is empty, that means to blank the prior tag (if any).z
    if new_tag.present?
      return nil if page_content.include? new_tag
    end

    # If we're removing the tag, also try to remove the immediately preceding
    # header, if it's there.
    header = new_tag.present? ? '' : section_header
    existing_tag = "{{#{template_name(@templates, 'course_assignment')} | course = #{@course_page}"

    # We're looking for an existing instance of the tag template, in the case of removing the tag,
    # we're also looking for the (optional) preceding section header. This way, when we're
    # removing a tag that is in the standard-format section, we remove the whole section rather
    # than leaving an empty one.

    if new_tag.present?
      replace_or_add_assignment_tag(page_content, existing_tag, new_tag)
    else
      remove_assignment_tag(page_content, existing_tag, header)
    end
  end

  def replace_or_add_assignment_tag(page_content, existing_tag, new_tag)
    tag_matcher = /
                    #{Regexp.quote(existing_tag)}[^}]*\}\} # assignment template
                    ([\n\r]+#{updated_by_signature_pattern})? # optional linebreaks and signature
                  /x
    new_tag_with_signature = if en_wiki?
                               "#{new_tag}\n#{updated_by_signature}"
                             else
                               new_tag
                             end
    page_content.gsub!(tag_matcher, new_tag_with_signature)

    # If we replaced an existing tag with the new version of it, we're done.
    return page_content if page_content.include?(new_tag_with_signature)

    # Otherwise, we need to add the tag to the right place.
    page_content = insert_tag_into_talk_page(page_content, new_tag_with_signature)
    page_content
  end

  def remove_assignment_tag(page_content, existing_tag, header)
    tag_matcher = /
                    (#{Regexp.quote(header)}[\n\r]+)? # optional header and linebreaks
                    #{Regexp.quote(existing_tag)}[^}]*\}\} # assignment template
                    ([\n\r]+#{updated_by_signature_pattern})? # optional linebreaks and signature
                  /x

    page_content.gsub!(tag_matcher, '')
    page_content
  end

  def starts_with_template?(page_content)
    initial_template_matcher = /
      \A   # beginning of page
      \s*  # optional whitespace
      \{\{ # beginning of a template
    /x

    initial_template_matcher.match(page_content)
  end

  # Regex to match "}}" at the end of a line where the next line does
  # NOT start with (optional whitespace and then) "|" or "{" or "}".
  # That covers the main syntax patterns of heavily-bannered talk pages,
  # which typically use something like the {{WikiProject banner shell}}
  # template that includes other templates within it.
  def end_of_templates_pattern
    /
      \}\}       # End of a template
      \n         # then a newline
      (?!        # that does not start with
        \s*      # optional whitespace
        \*?      # an optional bullet (used in some shell templates)
        \s*      # optional whitespace, then
        [{|}] # any of these characters: {|}
      )
    /x
  end

  def matches_talk_template_pattern?(page_content)
    end_of_templates_pattern.match(page_content)
  end

  def build_wikitext_user_list(role)
    user_ids = @assignments.select { |assignment| assignment.role == role }
                           .map(&:user_id)
    User.where(id: user_ids).pluck(:username)
        .map { |username| "[[User:#{username}|#{username}]]" }.join(', ')
  end

  private

  DISAMBIGUATION_TEMPLATE_FRAGMENTS = [
    '{{WikiProject Disambiguation',
    '{{disambig',
    '{{Disambig',
    '{{Dab}}',
    '{{dab}}',
    'disambiguation}}',
    '{{Hndis',
    '{{hndis',
    '{{Geodis',
    '{{geodis'
  ].freeze

  def includes_disambiguation_template?(page_content)
    DISAMBIGUATION_TEMPLATE_FRAGMENTS.any? do |template_fragment|
      page_content.include?(template_fragment)
    end
  end

  def insert_tag_into_talk_page(page_content, new_tag)
    if en_wiki?
      add_template_in_new_section(page_content, new_tag)
    else
      add_template_to_page_top(page_content, new_tag)
    end
  end

  def en_wiki?
    @wiki.language == 'en' && @wiki.project == 'wikipedia'
  end

  # This is what do on wikis other than English Wikipedia
  def add_template_to_page_top(page_content, template)
    # Append after existing templates, but only if there is no additional content
    # on the line where the templates end.
    if starts_with_template?(page_content) && matches_talk_template_pattern?(page_content)
      # Insert the assignment tag the end of the page-top templates
      page_content.sub!(end_of_templates_pattern, "}}\n#{template}\n")
    else # Add the tag to the top of the page
      page_content = "#{template}\n\n#{page_content}"
    end

    page_content
  end

  # This is what we do on English Wikipedia
  # based on the RfC here:
  # https://en.wikipedia.org/w/index.php?title=Wikipedia:Education_noticeboard&oldid=1072013453#How_should_Wiki_Education_assignments_be_announced_on_article_talk_page?
  def add_template_in_new_section(page_content, template)
    "#{page_content}\n\n#{section_header}\n#{template}\n#{updated_by_signature}\n"
  end

  def section_header
    "==Wiki Education assignment: #{@course.title}=="
  end

  def updated_by_signature
    return '' unless en_wiki?
    # rubocop:disable Layout/LineLength
    '<span class="wikied-assignment" style="font-size:85%;">— Assignment last updated by ~~~~</span>'
    # rubocop:enable Layout/LineLength
  end

  # rubocop:disable Layout/LineLength
  # Regex to match the wikied-assignment span tag of a signature, like this:
  # <span class="wikied-assignment" style="font-size:85%;">— Assignment last updated by [[User:Sage (Wiki Ed)|Sage (Wiki Ed)]] ([[User talk:Sage (Wiki Ed)|talk]]) 18:02, 11 May 2022 (UTC)</span>
  def updated_by_signature_pattern
    return '' unless en_wiki?
    opening_tag = '<span class="wikied-assignment" style="font-size:85%;">'
    closing_tag = '</span>'
    /#{Regexp.quote(opening_tag)}— Assignment last updated by .+#{Regexp.quote(closing_tag)}/
  end
  # rubocop:enable Layout/LineLength
end
