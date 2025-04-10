# frozen_string_literal: true
# Checks whether expected sandboxes have been created,
# or if they've been created already, checks their
# current size and location
class CheckAssignmentStatus
  def self.check_current_assignments
    return unless Features.wiki_ed?

    assignments = Assignment.joins(:course).merge(Course.current).where.not(user: nil)
    sandboxes_to_check = collect_sandboxes(assignments)

    process_sandboxes(sandboxes_to_check)
  end

  class << self
    private

    def collect_sandboxes(assignments)
      sandboxes = []
      assignments.each do |assignment|
        case assignment.role
        when Assignment::Roles::ASSIGNED_ROLE
          add_assigned_sandboxes(sandboxes, assignment)
        when Assignment::Roles::REVIEWING_ROLE
          add_assigned_sandboxes(sandboxes, assignment)
          add_review_sandbox(sandboxes, assignment)
        end
      end
      sandboxes
    end

    def add_assigned_sandboxes(sandboxes, assignment)
      sandboxes << { assignment:,
        key: :draft,
        wiki: assignment.wiki,
        pagename: assignment.sandbox_pagename }
      sandboxes << { assignment:,
        key: :bibliography,
        wiki: assignment.wiki,
        pagename: assignment.bibliography_pagename }
    end

    def add_review_sandbox(sandboxes, assignment)
      sandboxes << { assignment:,
        key: :review,
        wiki: assignment.wiki,
        pagename: assignment.peer_review_pagename }
    end

    def process_sandboxes(sandboxes)
      grouped_by_wiki = sandboxes.group_by { |s| s[:wiki] }

      grouped_by_wiki.each do |wiki, entries|
        pagenames = entries.map { |e| e[:pagename] }.uniq # rubocop:disable Rails/Pluck

        pagenames.each_slice(50) do |batch|
          api = WikiApi.new(wiki)
          page_infos = api.get_page_info(batch)

          process_batch(entries, batch, page_infos)
        end
      end
    end

    def process_batch(entries, batch, page_infos)
      return unless page_infos && page_infos['pages']

      pages_by_normalized_title = build_pages_by_normalized_title(page_infos)

      Assignment.transaction do
        update_assignments_for_batch(entries, batch, pages_by_normalized_title)
      end
    end

    def build_pages_by_normalized_title(page_infos)
      page_infos['pages'].each_with_object({}) do |(_, page), hash|
        normalized_title = page['title'].tr(' ', '_')
        page['present'] = !page.key?('missing')
        hash[normalized_title] = page
      end
    end

    def update_assignments_for_batch(entries, batch, pages_by_normalized_title)
      batch.each do |pagename|
        normalized_pagename = pagename.tr(' ', '_')
        page_data = pages_by_normalized_title[normalized_pagename]
        status = determine_status(page_data)

        update_entries_for_pagename(entries, pagename, status)
      end
    end

    def determine_status(page_data)
      if page_data
        status_from_namespace(page_data['ns'], page_data['present'])
      else
        AssignmentPipeline::SandboxStatuses::DOES_NOT_EXIST
      end
    end

    def update_entries_for_pagename(entries, pagename, status)
      entries.select { |e| e[:pagename] == pagename }.each do |entry|
        entry[:assignment].update_sandbox_status(entry[:key], status)
      end
    end

    def find_page_data(page_infos, pagename)
      page_infos['pages']&.values&.find { |pd| pd['title'] == pagename }
    end

    def status_from_namespace(namespace, present)
      return AssignmentPipeline::SandboxStatuses::DOES_NOT_EXIST unless present

      case namespace
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
  end
end
