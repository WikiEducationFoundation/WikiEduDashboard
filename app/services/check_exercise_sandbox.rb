# frozen_string_literal: true

# Checks whether the wiki pages a student is expected to create for an exercise
# exist yet, so that an exercise can't be marked complete before the student has
# done the required work.
#
# Two kinds of expected page are supported, both configured via the training
# module's YAML settings:
#
#   sandbox_location             a page under the student's own userpage, with
#                                the same title for every student, eg
#                                'Choose_an_Article'
#   assignment_sandbox_location  a subpage of the sandbox for an article the
#                                student has assigned themselves, eg
#                                'Bibliography'. The title varies per student,
#                                and a student with several assigned articles
#                                only needs the page for one of them.
class CheckExerciseSandbox
  # Titles of the expected pages that don't exist yet.
  attr_reader :missing_pages

  def initialize(training_module_user:, course:)
    @training_module_user = training_module_user
    @training_module = training_module_user.training_module
    @user = training_module_user.user
    @course = course
    @missing_pages = []
    @awaiting_article_assignment = false
    perform
  end

  def eligible?
    !@awaiting_article_assignment && @missing_pages.empty?
  end

  # An expected assignment sandbox has no title until the student has assigned
  # themselves an article, so there is nothing to look for yet.
  def awaiting_article_assignment?
    @awaiting_article_assignment
  end

  private

  def perform
    user_pages = user_sandbox_pages
    assignment_pages = assignment_sandbox_pages
    return if user_pages.empty? && assignment_pages.empty?

    present = present_pages(user_pages + assignment_pages)
    @missing_pages.concat user_pages.map(&:last).reject { |title| present.include? title }
    return if assignment_pages.empty?
    return if assignment_pages.any? { |_wiki, title| present.include? title }
    @missing_pages.concat assignment_pages.map(&:last)
  end

  # Each expected page is a [wiki, title] pair, since a student's assigned
  # articles are not necessarily all on the course's home wiki.
  def user_sandbox_pages
    return [] unless @training_module.sandbox_location
    # Via the API, we send the title without the URL encoding of special characters.
    [[@course.home_wiki, CGI.unescape(@training_module_user.exercise_sandbox_location)]]
  end

  def assignment_sandbox_pages
    location = @training_module.assignment_sandbox_location
    return [] unless location

    pages = @course.assignments.assigned.where(user: @user).map do |assignment|
      [assignment.wiki, "#{assignment.sandbox_pagename}/#{location}"]
    end
    @awaiting_article_assignment = pages.empty?
    pages
  end

  # Returns the subset of titles that exist and have content. Pages are looked
  # up one wiki at a time, so a student with several assigned articles still
  # only costs one API request.
  def present_pages(pages)
    pages.group_by(&:first).flat_map do |wiki, wiki_pages|
      present_titles(wiki, wiki_pages.map(&:last).uniq)
    end.to_set
  end

  def present_titles(wiki, titles)
    page_info = WikiApi.new(wiki).get_page_info(titles)
    # If the wiki can't be reached, don't stand in the student's way.
    return titles if page_info.nil?

    present = normalized_present_titles(page_info)
    titles.select { |title| present.include? title.tr(' ', '_') }
  end

  def normalized_present_titles(page_info)
    (page_info['pages'] || {}).each_value.filter_map do |page|
      next if page.key?('missing')
      next unless page['length'].to_i.positive?
      page['title'].tr(' ', '_')
    end.to_set
  end
end
