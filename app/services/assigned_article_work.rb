# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/student_progress/rules"
require_dependency "#{Rails.root}/lib/student_progress/roster"

# One student's state of work on their assigned article(s), for the in-Canvas
# drill-downs: where each piece of the writing process lives, whether it exists
# yet, and how much of the live article they have actually written.
#
# Assembled rather than computed — the Dashboard already tracks every part of
# this. Sandbox page names come off Assignment; whether each page exists comes
# from the statuses CheckAssignmentStatus maintains in `assignment.flags`
# (AssignmentPipeline reads them back); live-article contributions come from
# article_course_timeslices, which carry per-(course, article) totals plus the
# user_ids behind them.
#
# `editing` assignments only: a `reviewing` assignment is the peer-review stage,
# whose own column reports it (see LtiPeerReviewProgress).
#
# Built for a whole roster at once. A per-student query for each of these would
# be four round trips per row, so it reads the assignments and timeslices from a
# StudentProgress::Roster: the caller's, when it already has one for these
# students, or one of its own.
class AssignedArticleWork
  Article = Struct.new(:title, :url, :live, :pages, :stats, keyword_init: true)
  # `kind` is :bibliography / :outline / :draft — the view turns it into a label.
  Page = Struct.new(:kind, :url, :created, keyword_init: true)
  Stats = Struct.new(:characters, :references, :revisions, keyword_init: true)

  def initialize(course: nil, user_ids: [], roster: nil)
    @roster = roster || StudentProgress::Roster.new(course:, user_ids:)
    @course = @roster.course
    @by_user = build
  end

  def articles_for(user)
    return [] if user.nil?

    @by_user[user.id] || []
  end

  private

  def build
    assignments.group_by(&:user_id).transform_values do |for_user|
      for_user.map { |assignment| article_for(assignment) }
    end
  end

  def assignments
    @assignments ||= @roster.user_ids.flat_map { |id| @roster.assignments_for(id) }
                            .select(&:editing?)
  end

  def article_for(assignment)
    Article.new(
      # Stored underscored (Assignment normalizes titles through ArticleUtils);
      # de-underscored for display the way Article#full_title does.
      title: assignment.article_title.tr('_', ' '),
      url: assignment.article_url,
      # article_id is filled in once the live article exists on the wiki, so its
      # absence is exactly "nobody has created this article yet".
      live: assignment.article_id.present?,
      pages: pages_for(assignment),
      stats: stats_for(assignment)
    )
  end

  # The writing process, in the order a student works through it. The draft
  # sandbox is left out where the course has students editing live articles
  # instead of drafting (Course#no_sandboxes?) — there is no draft to point at.
  def pages_for(assignment)
    pages = [
      Page.new(kind: :bibliography, url: page_url(assignment, assignment.bibliography_pagename),
               created: created?(assignment.bibliography_sandbox_status)),
      Page.new(kind: :outline, url: page_url(assignment, assignment.outline_pagename),
               created: created?(assignment.outline_sandbox_status))
    ]
    return pages if @course.no_sandboxes?

    pages << Page.new(kind: :draft, url: assignment.sandbox_url,
                      created: created?(assignment.draft_sandbox_status))
  end

  def page_url(assignment, pagename)
    "#{assignment.wiki.base_url}/wiki/#{pagename}"
  end

  # The view's own preview fetch is the live check; this can trail it by an
  # update cycle.
  def created?(status)
    StudentProgress::Rules.page_created?(status)
  end

  # This student's share of the live article: the timeslices for that article
  # whose user_ids include them. Zeroes (rather than nil) for an article nobody
  # has edited yet, so the view has nothing to special-case.
  def stats_for(assignment)
    slices = @roster.timeslices_for(assignment.article_id).select do |slice|
      slice.user_ids.include?(assignment.user_id)
    end
    Stats.new(characters: slices.sum { |s| s.character_sum.to_i },
              references: slices.sum { |s| s.references_count.to_i },
              revisions: slices.sum { |s| s.revision_count.to_i })
  end
end
