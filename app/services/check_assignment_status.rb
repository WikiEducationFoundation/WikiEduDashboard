# frozen_string_literal: true

# Checks whether expected sandboxes have been created,
# or if they've been created already, checks their
# current size and location
class CheckAssignmentStatus
  def self.check_current_assignments
    return unless Features.wiki_ed?

    Course.current.each do |course|
      course.assignments.where.not(user: nil).each do |assignment|
        new(assignment)
      end
    end
  end

  def initialize(assignment)
    @assignment = assignment
    @sandboxes = {}

    case @assignment.role
    when Assignment::Roles::ASSIGNED_ROLE
      set_assigned_sandboxes
    when Assignment::Roles::REVIEWING_ROLE
      set_review_sandbox
    end

    update_status
    # what are the expected sandboxes?
    # do we already know that some of them exist?
    # what are the Article records for each of them that exist?
  end

  def set_assigned_sandboxes
    @sandboxes[:draft] = {
      wiki: @assignment.wiki,
      pagename: @assignment.sandbox_pagename
    }
    @sandboxes[:bibliography] = {
      wiki: @assignment.wiki,
      pagename: @assignment.bibliography_pagename
    }
  end

  def set_review_sandbox
    @sandboxes[:review] = {
      wiki: @assignment.wiki,
      pagename: @assignment.peer_review_pagename
    }
  end

  def update_status
    @sandboxes.each do |sandbox_key, page_details|
      info = WikiApi.new(page_details[:wiki]).get_page_info page_details[:pagename]
      new_status = page_status(info)
      @assignment.update_sandbox_status(sandbox_key, new_status)
    end
    # Do any already have corresponding Article records?
    # If not, have any been created?
    # If so, what namespaces are they in? what are their current titles? how big are they?
  end

  # Takes a hash of page info from the MediaWiki API and returns a status for
  # the Assignment record
  def page_status(page_info)
    return AssignmentPipeline::SandboxStatuses::DOES_NOT_EXIST unless page_present?(page_info)

    case page_info['pages'].values.first['ns']
    when Article::Namespaces::USER
      AssignmentPipeline::SandboxStatuses::EXISTS_IN_USERSPACE
    when Article::Namespaces::DRAFT
      AssignmentPipeline::SandboxStatuses::EXISTS_IN_DRAFT_SPACE
    when Article::Namespaces::MAINSPACE
      AssignmentPipeline::SandboxStatuses::EXISTS_IN_MAINSPACE
    else
      AssignmentPipeline::SandboxStatuses::EXISTS_ELSEWHERE
    end
  end

  def page_present?(page_info)
    page_info.dig('pages', '-1', 'missing').nil?
  end
end
