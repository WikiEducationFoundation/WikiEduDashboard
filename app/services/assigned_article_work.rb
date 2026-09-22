# frozen_string_literal: true

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
# be four round trips per row, so the constructor loads the course's assignments
# and timeslices once and indexes them by user.
class AssignedArticleWork
  Article = Struct.new(:title, :url, :live, :pages, :stats, keyword_init: true)
  # `kind` is :bibliography / :outline / :draft — the view turns it into a label.
  Page = Struct.new(:kind, :url, :created, keyword_init: true)
  Stats = Struct.new(:characters, :references, :revisions, keyword_init: true)

  def initialize(course:, user_ids:)
    @course = course
    @user_ids = user_ids.compact.uniq
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
    @assignments ||= Assignment.where(course_id: @course.id, user_id: @user_ids,
                                      role: Assignment::Roles::ASSIGNED_ROLE)
                               .includes(:wiki).to_a
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

  # The statuses distinguish where a page ended up (userspace, draft space,
  # mainspace, elsewhere); for "has the student started this yet" they all mean
  # yes. Only DOES_NOT_EXIST means no.
  #
  # These are refreshed by CheckAssignmentStatus rather than checked live, so a
  # page created minutes ago can still read as missing here. The view's own
  # preview fetch is the live check.
  def created?(status)
    status != AssignmentPipeline::SandboxStatuses::DOES_NOT_EXIST
  end

  # This student's share of the live article: the timeslices for that article
  # whose user_ids include them. Zeroes (rather than nil) for an article nobody
  # has edited yet, so the view has nothing to special-case.
  def stats_for(assignment)
    slices = timeslices_for(assignment.article_id).select do |slice|
      slice.user_ids.include?(assignment.user_id)
    end
    Stats.new(characters: slices.sum { |s| s.character_sum.to_i },
              references: slices.sum { |s| s.references_count.to_i },
              revisions: slices.sum { |s| s.revision_count.to_i })
  end

  def timeslices_for(article_id)
    return [] if article_id.nil?

    timeslices[article_id] || []
  end

  # One query for every assigned article in the course. `non_empty` skips the
  # slices with no contributors, which are the bulk of them.
  def timeslices
    @timeslices ||= ArticleCourseTimeslice
                    .where(course_id: @course.id, article_id: assignments.map(&:article_id).compact)
                    .non_empty
                    .group_by(&:article_id)
  end
end
