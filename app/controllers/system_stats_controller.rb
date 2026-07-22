# frozen_string_literal: true

# Admin analytics dashboard for system-wide metrics and facilitator stats.
# Not to be confused with SystemStatusController (/status), which is a
# health-check endpoint.
class SystemStatsController < ApplicationController
  before_action :require_admin_permissions

  def index
    respond_to do |format|
      format.html { render }
      format.json { render json: index_json_data }
    end
  end

  def wiki_trends
    render json: wiki_trends_json_data
  end

  def facilitators
    render json: { facilitators: facilitators_data }
  end

  private

  def index_json_data
    latest_snapshot = SystemStat.current
    snapshots = SystemStat.recent_monthly_snapshots(13, include_wiki_stats: false)
    {
      kpis: kpis_for(latest_snapshot),
      trends: trends_for(snapshots),
      campaigns: Campaign.select(:slug, :title).order(:title)
                          .map { |c| { slug: c.slug, title: c.title } },
      wikis: Wiki.select(:language, :project)
                 .map(&:domain).compact.uniq.sort
    }
  end

  def wiki_trends_json_data
    snapshots = SystemStat.recent_monthly_snapshots(13, include_wiki_stats: true)
    display_snapshots = snapshots[trend_snapshots_range(snapshots)]
    {
      months: display_snapshots.map { |s| s.snapshot_date.to_s },
      wiki_trends: wiki_trends_for(snapshots),
      wiki_stats: wiki_stats_for(SystemStat.current)
    }
  end

  def facilitators_data
    stats = FacilitatorStat.current.order(total_edits: :desc).first(100)
    stats.map do |s|
      {
        username: s.user.username,
        courses: s.total_programs_count,
        activeCourses: s.active_programs_count,
        edits: s.total_edits,
        students: s.total_students_count,
        newEditors: s.new_editors_count_with_preregistration,
        activeInYear: s.active_in_last_year
      }
    end
  end

  def kpis_for(latest_snapshot)
    return empty_kpis unless latest_snapshot
    {
      edits: latest_snapshot.total_edits,
      articleViews: latest_snapshot.total_article_views,
      articlesCreated: latest_snapshot.total_articles_created,
      articlesImproved: latest_snapshot.total_articles_improved,
      charactersAdded: latest_snapshot.total_characters_added,
      newEditors: latest_snapshot.new_editors_count_with_preregistration,
      activePrograms: latest_snapshot.active_programs_count,
      activeFacilitators: latest_snapshot.active_facilitators_count
    }
  end

  def empty_kpis
    { edits: 0, articleViews: 0, articlesCreated: 0, articlesImproved: 0,
      charactersAdded: 0, newEditors: 0, activePrograms: 0, activeFacilitators: 0 }
  end

  def trend_snapshots_range(snapshots)
    start_idx = snapshots.length > 1 ? 1 : 0
    (start_idx...snapshots.length)
  end

  def trends_for(snapshots)
    return [] if snapshots.empty?

    prev = snapshots.first

    trend_snapshots_range(snapshots).map do |i|
      curr = snapshots[i]
      base = i.zero? ? nil : prev
      prev = curr
      snapshot_trend_point(curr, base)
    end
  end

  def snapshot_trend_point(curr, base)
    {
      month: curr.snapshot_date.to_s,
      edits: calculate_delta(curr.total_edits, base&.total_edits),
      articleViews: calculate_delta(curr.total_article_views, base&.total_article_views),
      articlesCreated: calculate_delta(curr.total_articles_created, base&.total_articles_created),
      articlesImproved: calculate_delta(curr.total_articles_improved,
                                        base&.total_articles_improved),
      charactersAdded: calculate_delta(curr.total_characters_added, base&.total_characters_added),
      newEditors: calculate_delta(curr.new_editors_count_with_preregistration,
                                  base&.new_editors_count_with_preregistration),
      activePrograms: curr.active_programs_count,
      activeFacilitators: curr.active_facilitators_count
    }
  end

  def calculate_delta(current_val, previous_val)
    return current_val.to_i unless previous_val
    delta = current_val.to_i - previous_val.to_i
    delta.positive? ? delta : 0
  end

  def wiki_trends_for(snapshots)
    return {} if snapshots.empty?

    wiki_domains = snapshots.flat_map { |s| (s.wiki_stats || {}).keys }.uniq
    wiki_trends_data = wiki_domains.each_with_object({}) do |domain, hash|
      hash[domain] = { edits: [], programs: [], articles_created: [], new_editors: [] }
    end

    populate_wiki_trends(snapshots, wiki_domains, wiki_trends_data)
    wiki_trends_data
  end

  def populate_wiki_trends(snapshots, wiki_domains, wiki_trends_data)
    trend_snapshots_range(snapshots).each do |i|
      curr_stats = snapshots[i].wiki_stats || {}
      prev_stats = (i.zero? ? {} : snapshots[i - 1].wiki_stats) || {}

      wiki_domains.each do |domain|
        append_wiki_trend_metrics(wiki_trends_data[domain], curr_stats[domain] || {},
                                  prev_stats[domain] || {}, i.zero?)
      end
    end
  end

  def append_wiki_trend_metrics(trends, curr_data, prev_data, is_first)
    base_editors = is_first ? nil : prev_data['new_editors_with_preregistration']
    trends[:edits] << calculate_delta(curr_data['edits'], is_first ? nil : prev_data['edits'])
    trends[:programs] << (curr_data['programs'] || 0)
    trends[:articles_created] << calculate_delta(curr_data['articles_created'],
                                                 is_first ? nil : prev_data['articles_created'])
    trends[:new_editors] << calculate_delta(curr_data['new_editors_with_preregistration'],
                                            base_editors)
  end

  def wiki_stats_for(latest_snapshot)
    return [] unless latest_snapshot
    wiki_data = (latest_snapshot.wiki_stats || {}).map do |domain, stats|
      {
        name: domain,
        edits: stats['edits'] || 0,
        programs: stats['programs'] || 0,
        articles_created: stats['articles_created'] || 0,
        new_editors: stats['new_editors_with_preregistration'] || 0
      }
    end
    wiki_data.sort_by { |w| -w[:edits] }.first(100)
  end
end
