# frozen_string_literal: true

class SystemStatsController < ApplicationController
  before_action :require_admin_permissions

  def index
    respond_to do |format|
      format.html { render }
      format.json do
        latest_snapshot = SystemStat.current

        kpis = if latest_snapshot
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
                 { edits: 0, articleViews: 0, articlesCreated: 0, articlesImproved: 0,
                   charactersAdded: 0, newEditors: 0, activePrograms: 0, activeFacilitators: 0 }
               end

        # Monthly Activity Trends (last 12 months)
        recent_snapshots = SystemStat.order(:snapshot_date).where('snapshot_date >= ?', 12.months.ago.to_date)
        monthly_snapshots_dates = recent_snapshots.group_by { |s| s.snapshot_date.strftime('%Y-%m') }
                                                 .map { |_month, group| group.max_by(&:snapshot_date).snapshot_date }
        trends = SystemStat.where(snapshot_date: monthly_snapshots_dates).order(:snapshot_date).map do |s|
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

        render json: {
          kpis: kpis,
          trends: trends
        }
      end
    end
  end

  def wiki_trends
    respond_to do |format|
      format.json do
        # Wiki trends (graph) — last 12 months
        recent_snapshots = SystemStat.order(:snapshot_date).where('snapshot_date >= ?', 12.months.ago.to_date)
        monthly_snapshots_dates = recent_snapshots.group_by { |s| s.snapshot_date.strftime('%Y-%m') }
                                                 .map { |_month, group| group.max_by(&:snapshot_date).snapshot_date }
        snapshots = SystemStat.where(snapshot_date: monthly_snapshots_dates).order(:snapshot_date)

        months = snapshots.map { |s| s.snapshot_date.strftime('%b %Y') }
        wiki_domains = snapshots.flat_map { |s| (s.wiki_stats || {}).keys }.uniq

        wiki_trends_data = {}
        wiki_domains.each do |domain|
          wiki_trends_data[domain] = {
            edits: [],
            programs: [],
            articles_created: [],
            new_editors: []
          }
        end

        snapshots.each do |s|
          stats_for_date = s.wiki_stats || {}
          wiki_domains.each do |domain|
            wiki_data = stats_for_date[domain] || {}
            wiki_trends_data[domain][:edits] << (wiki_data['edits'] || 0)
            wiki_trends_data[domain][:programs] << (wiki_data['programs'] || 0)
            wiki_trends_data[domain][:articles_created] << (wiki_data['articles_created'] || wiki_data['articles_created_count'] || 0)
            wiki_trends_data[domain][:new_editors] << (wiki_data['new_editors_with_preregistration'] || wiki_data['new_editors'] || 0)
          end
        end

        # Wiki stats breakdown (top 5) from latest snapshot
        latest_snapshot = SystemStat.current
        wiki_data = if latest_snapshot
                      (latest_snapshot.wiki_stats || {}).map do |domain, stats|
                        {
                          name: domain,
                          edits: stats['edits'] || 0,
                          programs: stats['programs'] || 0,
                          articles_created: stats['articles_created'] || stats['articles_created_count'] || 0,
                          new_editors: stats['new_editors_with_preregistration'] || stats['new_editors'] || 0
                        }
                      end
                    else
                      []
                    end

        wiki_data = wiki_data.sort_by { |w| -w[:edits] }.first(5)

        render json: {
          months: months,
          wiki_trends: wiki_trends_data,
          wiki_stats: wiki_data
        }
      end
    end
  end

  def facilitators
    respond_to do |format|
      format.json do
        stats = FacilitatorStat.current.order(total_edits: :desc).first(5)
        facilitators_data = stats.map do |s|
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

        render json: {
          facilitators: facilitators_data
        }
      end
    end
  end
end
