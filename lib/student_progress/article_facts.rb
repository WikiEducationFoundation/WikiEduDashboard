# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/student_progress/rules"
require_dependency "#{Rails.root}/lib/student_progress/roster"

module StudentProgress
  # Each roster student's state of work on their assigned article(s): where
  # each piece of the writing process lives, whether it exists yet, where the
  # student says they are in it, and how much of the live article they have
  # actually written. One entry per assignment, so a student with two articles
  # has two independent entries.
  #
  # Assembled rather than computed — the Dashboard already tracks every part of
  # this. Sandbox page names come off Assignment; whether each page exists comes
  # from the statuses CheckAssignmentStatus maintains in `assignment.flags`
  # (AssignmentPipeline reads them back); live-article contributions come from
  # article_course_timeslices, which carry per-(course, article) totals plus the
  # user_ids behind them.
  #
  # `editing` assignments only: a `reviewing` assignment is the peer-review
  # stage (see PeerReviewFacts).
  class ArticleFacts
    # `status` is the student's own place in the pipeline (AssignmentPipeline);
    # `statuses` is the pipeline it comes from, which depends on the course's
    # sandbox mode. `status_updated_at` is nil until the student first sets one.
    # `article_id`, `mw_page_id`, `language` and `project` are what the article
    # viewer needs to open the live article; the ids are nil until it exists.
    Article = Struct.new(:assignment_id, :title, :url, :live, :pages, :stats, :status,
                         :statuses, :status_updated_at, :assigned_at, :article_id,
                         :mw_page_id, :language, :project, keyword_init: true)
    # `kind` is :bibliography / :outline / :draft — the view turns it into a label.
    Page = Struct.new(:kind, :url, :created, keyword_init: true)
    Stats = Struct.new(:characters, :references, :revisions, keyword_init: true)

    # Before this, a student claiming an Available Article took over its
    # existing record without marking it, so an older record's creation time
    # may be when the article was made available rather than when the student
    # got it. The `available_article` flag arrived in 7ba09badb (2025-01-10);
    # this allows for it reaching production.
    AVAILABLE_ARTICLE_FLAG_SINCE = Time.zone.parse('2025-02-01')

    def initialize(roster)
      @roster = roster
      @course = roster.course
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
        assignment_id: assignment.id,
        # Stored underscored (Assignment normalizes titles through ArticleUtils);
        # de-underscored for display the way Article#full_title does.
        title: assignment.article_title.tr('_', ' '),
        url: assignment.article_url,
        # article_id is filled in once the live article exists on the wiki, so
        # its absence is exactly "nobody has created this article yet".
        live: assignment.article_id.present?,
        article_id: assignment.article_id, mw_page_id: assignment.article&.mw_page_id,
        language: assignment.wiki.language, project: assignment.wiki.project,
        pages: pages_for(assignment),
        stats: stats_for(assignment),
        status: assignment.status,
        statuses: assignment.all_statuses,
        status_updated_at: assignment.status_updated_at,
        assigned_at: assigned_at(assignment)
      )
    end

    # When the student got the article: the record's creation, when that is
    # what it means. Not for a claimed Available Article, whose record was
    # created when the article was made available and then handed to the
    # student (unless the course retains available articles, in which case
    # claiming creates a fresh, unflagged record); nor for records from before
    # claims were flagged, which can't be told apart.
    def assigned_at(assignment)
      return if assignment.flags[:available_article]
      return if assignment.created_at < AVAILABLE_ARTICLE_FLAG_SINCE

      assignment.created_at
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

    # A view's own preview fetch is the live check; this can trail it by an
    # update cycle.
    def created?(status)
      Rules.page_created?(status)
    end

    # This student's share of the live article: the timeslices for that article
    # whose user_ids include them. Zeroes (rather than nil) for an article nobody
    # has edited yet, so a view has nothing to special-case.
    def stats_for(assignment)
      slices = @roster.timeslices_for(assignment.article_id).select do |slice|
        slice.user_ids.include?(assignment.user_id)
      end
      Stats.new(characters: slices.sum { |s| s.character_sum.to_i },
                references: slices.sum { |s| s.references_count.to_i },
                revisions: slices.sum { |s| s.revision_count.to_i })
    end
  end
end
