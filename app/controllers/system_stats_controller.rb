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
    respond_to do |format|
      format.json { render json: wiki_trends_json_data }
    end
  end

  def facilitators
    respond_to do |format|
      format.json { render json: { facilitators: facilitators_data } }
    end
  end

  private

  def index_json_data
    latest_snapshot = SystemStat.current
    snapshots = recent_monthly_snapshots
    {
      kpis: kpis_for(latest_snapshot),
      trends: trends_for(snapshots)
    }
  end

  def wiki_trends_json_data
    snapshots = recent_monthly_snapshots
    {
      months: snapshots.map { |s| s.snapshot_date.strftime('%b %Y') },
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
        activeInYear: s.active_in_last_year ? 'Yes' : 'No'
      }
    end
  end

  def recent_monthly_snapshots
    SystemStat.where('snapshot_date >= ?', 12.months.ago.to_date)
              .order(:snapshot_date)
              .group_by { |s| s.snapshot_date.strftime('%Y-%m') }
              .values
              .map(&:last)
  end

  def kpis_for(latest_snapshot)
    if latest_snapshot
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
    else
      empty_kpis
    end
  end

  def empty_kpis
    { edits: 0, articleViews: 0, articlesCreated: 0, articlesImproved: 0,
      charactersAdded: 0, newEditors: 0, activePrograms: 0, activeFacilitators: 0 }
  end

  def trends_for(snapshots)
    snapshots.map do |s|
      {
        month: s.snapshot_date.strftime('%b %Y'),
        edits: s.total_edits,
        articleViews: s.total_article_views,
        articlesCreated: s.total_articles_created,
        articlesImproved: s.total_articles_improved,
        charactersAdded: s.total_characters_added,
        newEditors: s.new_editors_count_with_preregistration,
        activePrograms: s.active_programs_count,
        activeFacilitators: s.active_facilitators_count
      }
    end
  end

  def wiki_trends_for(snapshots)
    wiki_domains = snapshots.flat_map { |s| (s.wiki_stats || {}).keys }.uniq
    wiki_trends_data = initialize_wiki_trends(wiki_domains)
    populate_wiki_trends(snapshots, wiki_domains, wiki_trends_data)
  end

  def initialize_wiki_trends(wiki_domains)
    wiki_domains.each_with_object({}) do |domain, hash|
      hash[domain] = { edits: [], programs: [], articles_created: [], new_editors: [] }
    end
  end

  def populate_wiki_trends(snapshots, wiki_domains, wiki_trends_data)
    snapshots.each do |s|
      stats_for_date = s.wiki_stats || {}
      wiki_domains.each do |domain|
        wiki_data = stats_for_date[domain] || {}
        append_wiki_trend_metrics(wiki_trends_data[domain], wiki_data)
      end
    end
    wiki_trends_data
  end

  def append_wiki_trend_metrics(trends, wiki_data)
    trends[:edits] << (wiki_data['edits'] || 0)
    trends[:programs] << (wiki_data['programs'] || 0)
    trends[:articles_created] << (wiki_data['articles_created'] || 0)
    trends[:new_editors] << (wiki_data['new_editors_with_preregistration'] || 0)
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
