import React, { useState, useEffect } from 'react';
import OverviewStat from '../common/OverviewStats/overview_stat';
import request from '../../utils/request';
import MonthlyActivityChart from './monthly_activity_chart';
import WikiTrendsChart from './wiki_trends_chart';
import WikiStatsBreakdown from './wiki_stats_breakdown';
import FacilitatorLeaderboard from './facilitator_leaderboard';
import SystemCsvExportBar from './system_csv_export_bar';

const formatHumanNumber = (num) => {
  if (num === undefined || num === null) return '0';
  const abs = Math.abs(num);
  if (abs >= 1.0e9) {
    return `${(num / 1.0e9).toFixed(1).replace(/\.0$/, '')}B`;
  }
  if (abs >= 1.0e6) {
    return `${(num / 1.0e6).toFixed(1).replace(/\.0$/, '')}M`;
  }
  if (abs >= 1.0e3) {
    return `${(num / 1.0e3).toFixed(1).replace(/\.0$/, '')}K`;
  }
  return num.toLocaleString();
};

const SystemStatsHandler = () => {
  const [stats, setStats] = useState(null);
  const [wikiTrends, setWikiTrends] = useState(null);
  const [loading, setLoading] = useState(true);
  const [loadingWikiTrends, setLoadingWikiTrends] = useState(true);
  const [error, setError] = useState(null);

  // Fetch KPIs + monthly trends
  useEffect(() => {
    setLoading(true);
    request('/system_stats.json')
      .then(resp => {
        if (!resp.ok) {
          throw new Error('Failed to fetch system stats');
        }
        return resp.json();
      })
      .then(data => {
        setStats(data);
        setLoading(false);
      })
      .catch(err => {
        console.error(err);
        setError(I18n.t('system_stats.errors.fetch_failed'));
        setLoading(false);
      });
  }, []);

  // Fetch wiki trends + wiki stats breakdown
  useEffect(() => {
    setLoadingWikiTrends(true);
    request('/system_stats/wiki_trends.json')
      .then(resp => {
        if (!resp.ok) {
          throw new Error('Failed to fetch wiki trends');
        }
        return resp.json();
      })
      .then(data => {
        setWikiTrends(data);
        setLoadingWikiTrends(false);
      })
      .catch(err => {
        console.error(err);
        setError(I18n.t('system_stats.errors.fetch_failed'));
        setLoadingWikiTrends(false);
      });
  }, []);

  const activeStats = stats || {
    kpis: {
      edits: 0,
      articleViews: 0,
      articlesCreated: 0,
      articlesImproved: 0,
      charactersAdded: 0,
      newEditors: 0,
      activePrograms: 0,
      activeFacilitators: 0
    },
    trends: []
  };

  const formattedKpis = {
    edits: formatHumanNumber(activeStats.kpis.edits),
    articleViews: formatHumanNumber(activeStats.kpis.articleViews),
    articlesCreated: formatHumanNumber(activeStats.kpis.articlesCreated),
    articlesImproved: formatHumanNumber(activeStats.kpis.articlesImproved),
    charactersAdded: formatHumanNumber(activeStats.kpis.charactersAdded),
    newEditors: formatHumanNumber(activeStats.kpis.newEditors),
    activePrograms: activeStats.kpis.activePrograms,
    activeFacilitators: activeStats.kpis.activeFacilitators
  };

  return (
    <>
      {/* Header */}
      <header className="main-page system-stats-header">
        <div className="header">
          <h1>{I18n.t('system_stats.title')}</h1>
        </div>
      </header>

      <div className="overview container">
        {/* Error Banner */}
        {error && (
          <div className="notification" role="alert">
            <div className="container">
              <p>{error}</p>
            </div>
          </div>
        )}

        {/* Filter & Export Bar */}
        <SystemCsvExportBar
          campaigns={activeStats.campaigns || []}
          wikis={activeStats.wikis || []}
        />

        {/* Loading Spinner Overlay or Main Block */}
        {loading && !stats ? (
          <div className="loading system-stats__loading-container">
            <div className="loading__spinner" />
            <p className="system-stats__loading-text">{I18n.t('system_stats.loading.data')}</p>
          </div>
        ) : (
          <>
            {/* KPI Stats */}
            <div className={`stat-display system-stats__stat-display${loading ? ' system-stats__faded' : ''}`}>
              <OverviewStat id="total-edits" className="stat-display__value" stat={formattedKpis.edits} statMsg={I18n.t('system_stats.kpis.total_edits')} renderZero={true} />
              <OverviewStat id="article-views" className="stat-display__value" stat={formattedKpis.articleViews} statMsg={I18n.t('system_stats.kpis.article_views')} renderZero={true} />
              <OverviewStat id="articles-created" className="stat-display__value" stat={formattedKpis.articlesCreated} statMsg={I18n.t('system_stats.kpis.articles_created')} renderZero={true} />
              <OverviewStat id="articles-improved" className="stat-display__value" stat={formattedKpis.articlesImproved} statMsg={I18n.t('system_stats.kpis.articles_improved')} renderZero={true} />
              <OverviewStat id="characters-added" className="stat-display__value" stat={formattedKpis.charactersAdded} statMsg={I18n.t('system_stats.kpis.characters_added')} renderZero={true} />
              <OverviewStat id="new-editors" className="stat-display__value" stat={formattedKpis.newEditors} statMsg={I18n.t('system_stats.kpis.new_editors')} renderZero={true} />
              <OverviewStat id="active-programs" className="stat-display__value" stat={formattedKpis.activePrograms} statMsg={I18n.t('system_stats.kpis.active_programs')} renderZero={true} />
              <OverviewStat id="active-facilitators" className="stat-display__value" stat={formattedKpis.activeFacilitators} statMsg={I18n.t('system_stats.kpis.active_facilitators')} renderZero={true} />
            </div>
          </>
        )}
      </div>

      {(!loading || stats) && (
        <div className={loading ? 'system-stats__faded' : ''}>
          {/* Charts */}
          <div className="container">
            <div className="system-stats__charts">
              <MonthlyActivityChart trends={activeStats.trends} />
              <WikiTrendsChart wikiTrends={wikiTrends} loading={loadingWikiTrends} />
            </div>

            {/* Wiki Stats Breakdown Table */}
            <WikiStatsBreakdown wikiTrends={wikiTrends} loading={loadingWikiTrends} />
          </div>

          {/* Facilitator Leaderboard */}
          <FacilitatorLeaderboard />
        </div>
      )}
    </>
  );
};

export default SystemStatsHandler;
