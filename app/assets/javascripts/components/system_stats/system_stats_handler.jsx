/* eslint-disable i18next/no-literal-string */
import React, { useState, useEffect, useRef } from 'react';
import Chart from 'chart.js/auto';
import OverviewStat from '../common/OverviewStats/overview_stat';
import request from '../../utils/request';

const METRIC_CONFIG = {
  edits: { label: 'Total Edits', color: '#38a169', bg: 'rgba(56, 161, 105, 0.1)' },
  articleViews: { label: 'Article Views', color: '#e53e3e', bg: 'rgba(229, 62, 62, 0.1)' },
  articlesCreated: { label: 'Articles Created', color: '#3182ce', bg: 'rgba(49, 130, 206, 0.1)' },
  articlesImproved: { label: 'Articles Improved', color: '#805ad5', bg: 'rgba(128, 90, 213, 0.1)' },
  charactersAdded: { label: 'Characters Added', color: '#dd6b20', bg: 'rgba(221, 107, 32, 0.1)' },
  newEditors: { label: 'New Editors', color: '#319795', bg: 'rgba(49, 151, 149, 0.1)' },
  activePrograms: { label: 'Active Programs', color: '#d69e2e', bg: 'rgba(214, 158, 46, 0.1)' },
  activeFacilitators: { label: 'Active Facilitators', color: '#4a5568', bg: 'rgba(74, 85, 104, 0.1)' }
};

const WIKI_METRIC_CONFIG = {
  edits: { label: 'Edits' },
  programs: { label: 'Programs' },
  articles_created: { label: 'Articles Created' },
  new_editors: { label: 'New Editors' }
};

const WIKI_COLORS = [
  '#3182ce', // Blue
  '#38a169', // Green
  '#805ad5', // Purple
  '#e53e3e', // Red
  '#dd6b20', // Orange
  '#319795', // Teal
  '#d69e2e', // Yellow
  '#4a5568', // Slate/Gray
  '#d53f8c', // Pink
  '#0967d2', // Darker Blue
  '#0f766e'  // Darker Teal
];

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
  // Filter state — UI-only placeholders for now, backend wiring coming later
  const [campaign, setCampaign] = useState('all');
  const [wiki, setWiki] = useState('all');
  const [startDate, setStartDate] = useState('2025-07-01');
  const [endDate, setEndDate] = useState('2026-06-30');
  const campaigns = [{ slug: 'all', name: 'All Campaigns' }];
  const wikis = [{ id: 'all', name: 'All Wikis' }];

  const [selectedMetric, setSelectedMetric] = useState('edits');
  const [selectedWikiMetric, setSelectedWikiMetric] = useState('edits');
  const [sortField, setSortField] = useState('edits');
  const [sortOrder, setSortOrder] = useState('desc');
  const [isExporting, setIsExporting] = useState(false);
  const [exportMessage, setExportMessage] = useState('');
  const [stats, setStats] = useState(null);
  const [wikiTrends, setWikiTrends] = useState(null);
  const [facilitators, setFacilitators] = useState(null);
  const [loading, setLoading] = useState(true);
  const [loadingWikiTrends, setLoadingWikiTrends] = useState(true);
  const [loadingFacilitators, setLoadingFacilitators] = useState(true);

  const trendChartRef = useRef(null);
  const wikiChartRef = useRef(null);
  const trendChartInstance = useRef(null);
  const wikiChartInstance = useRef(null);

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
        setLoadingWikiTrends(false);
      });
  }, []);

  // Fetch facilitator leaderboard
  useEffect(() => {
    setLoadingFacilitators(true);
    request('/system_stats/facilitators.json')
      .then(resp => {
        if (!resp.ok) {
          throw new Error('Failed to fetch facilitators');
        }
        return resp.json();
      })
      .then(data => {
        setFacilitators(data.facilitators);
        setLoadingFacilitators(false);
      })
      .catch(err => {
        console.error(err);
        setLoadingFacilitators(false);
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

  // Render/Update trend chart
  useEffect(() => {
    if (!stats || !stats.trends || stats.trends.length === 0) return;
    if (trendChartInstance.current) {
      trendChartInstance.current.destroy();
    }

    const ctx = trendChartRef.current.getContext('2d');
    const metricConfig = METRIC_CONFIG[selectedMetric];

    trendChartInstance.current = new Chart(ctx, {
      type: 'line',
      data: {
        labels: activeStats.trends.map(t => t.month),
        datasets: [
          {
            label: metricConfig.label,
            data: activeStats.trends.map(t => t[selectedMetric]),
            borderColor: metricConfig.color,
            backgroundColor: metricConfig.bg,
            tension: 0.3,
            fill: true,
            yAxisID: 'y'
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            position: 'top',
            labels: {
              boxWidth: 12,
              usePointStyle: true,
              pointStyle: 'circle'
            }
          }
        },
        scales: {
          x: {
            grid: {
              display: false
            }
          },
          y: {
            type: 'linear',
            display: true,
            position: 'left',
            title: {
              display: true,
              text: metricConfig.label
            },
            grid: {
              color: '#e2e8f0'
            }
          }
        }
      }
    });

    return () => {
      if (trendChartInstance.current) {
        trendChartInstance.current.destroy();
      }
    };
  }, [stats, selectedMetric]);

  // Render/Update wiki trends line chart
  useEffect(() => {
    if (loadingWikiTrends || !wikiTrends || !wikiTrends.wiki_trends || Object.keys(wikiTrends.wiki_trends).length === 0) return;
    if (!wikiChartRef.current) return;
    if (wikiChartInstance.current) {
      wikiChartInstance.current.destroy();
    }

    const ctx = wikiChartRef.current.getContext('2d');
    // Limit to top 5 wikis (by latest value of selected metric)
    const wikiEntries = Object.entries(wikiTrends.wiki_trends);
    const top5Wikis = wikiEntries
      .map(([domain, metrics]) => {
        const values = metrics[selectedWikiMetric] || [];
        const latest = values.length > 0 ? values[values.length - 1] : 0;
        return { domain, metrics, latest };
      })
      .sort((a, b) => b.latest - a.latest)
      .slice(0, 5);

    const datasets = top5Wikis.map(({ domain, metrics }, index) => {
      const color = WIKI_COLORS[index % WIKI_COLORS.length];
      return {
        label: domain,
        data: metrics[selectedWikiMetric] || [],
        borderColor: color,
        backgroundColor: color,
        tension: 0.3,
        fill: false
      };
    });

    wikiChartInstance.current = new Chart(ctx, {
      type: 'line',
      data: {
        labels: wikiTrends.months,
        datasets: datasets
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            position: 'top',
            labels: {
              boxWidth: 12,
              usePointStyle: true,
              pointStyle: 'circle'
            }
          }
        },
        scales: {
          x: {
            grid: {
              display: false
            }
          },
          y: {
            type: 'linear',
            display: true,
            title: {
              display: true,
              text: WIKI_METRIC_CONFIG[selectedWikiMetric].label
            },
            grid: {
              color: '#e2e8f0'
            }
          }
        }
      }
    });

    return () => {
      if (wikiChartInstance.current) {
        wikiChartInstance.current.destroy();
      }
    };
  }, [wikiTrends, selectedWikiMetric, loadingWikiTrends]);

  const handleExportCSV = () => {
    setIsExporting(true);
    setExportMessage('Generating your CSV export...');
    setTimeout(() => {
      setIsExporting(false);
      setExportMessage('CSV successfully generated! Click here to download.');
      const facilitatorsList = facilitators || [];
      const csvContent = "data:text/csv;charset=utf-8,Username,Courses,Active,Edits,Students,NewEditors,ActiveInYear\n" +
        facilitatorsList.map(f => `${f.username},${f.courses},${f.activeCourses},${f.edits},${f.students},${f.newEditors},${f.activeInYear}`).join("\n");
      const encodedUri = encodeURI(csvContent);
      const link = document.createElement("a");
      link.setAttribute("href", encodedUri);
      link.setAttribute("download", "system_stats_export.csv");
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
    }, 1000);
  };

  const handleSort = (field) => {
    if (sortField === field) {
      setSortOrder(sortOrder === 'asc' ? 'desc' : 'asc');
    } else {
      setSortField(field);
      setSortOrder('desc');
    }
  };

  const filteredAndSortedFacilitators = (facilitators || [])
    .sort((a, b) => {
      let valA = a[sortField];
      let valB = b[sortField];
      if (typeof valA === 'string') {
        return sortOrder === 'asc' ? valA.localeCompare(valB) : valB.localeCompare(valA);
      }
      return sortOrder === 'asc' ? valA - valB : valB - valA;
    });

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
      <header className="main-page">
        <div className="header">
          <h1>System &amp; Facilitator Stats</h1>
        </div>
      </header>

      {/* Filters + Export CSV */}
      <div className="overview container">
        <div className="system-stats__filters">
          <div className="system-stats__filter-group">
            <label htmlFor="campaign-select">Campaign</label>
            <select id="campaign-select" value={campaign} onChange={(e) => setCampaign(e.target.value)}>
              {campaigns.map(c => (
                <option key={c.slug} value={c.slug}>{c.name}</option>
              ))}
            </select>
          </div>
          <div className="system-stats__filter-group">
            <label htmlFor="wiki-select">Home Wiki</label>
            <select id="wiki-select" value={wiki} onChange={(e) => setWiki(e.target.value)}>
              {wikis.map(w => (
                <option key={w.id} value={w.id}>{w.name}</option>
              ))}
            </select>
          </div>
          <div className="system-stats__filter-group">
            <label htmlFor="start-date">Start Date</label>
            <input type="date" id="start-date" value={startDate} onChange={(e) => setStartDate(e.target.value)} />
          </div>
          <div className="system-stats__filter-group">
            <label htmlFor="end-date">End Date</label>
            <input type="date" id="end-date" value={endDate} onChange={(e) => setEndDate(e.target.value)} />
          </div>
          <div className="system-stats__filter-group system-stats__filter-actions">
            <button onClick={handleExportCSV} disabled={isExporting} className="button dark">
              {isExporting ? 'Generating...' : 'Export CSV'}
            </button>
          </div>
        </div>

        {exportMessage && (
          <div className="notification">
            <div className="container">
              <p>{exportMessage}</p>
            </div>
          </div>
        )}

        {/* Loading Spinner Overlay or Main Block */}
        {loading && !stats ? (
          <div className="loading" style={{ minHeight: '200px', display: 'flex', flexDirection: 'column', justifyContent: 'center', alignItems: 'center' }}>
            <div className="loading__spinner" />
            <p style={{ marginTop: '15px', color: '#718096' }}>Loading data from server...</p>
          </div>
        ) : (
          <>
            {/* KPI Stats */}
            <div className="stat-display" style={{ opacity: loading ? 0.6 : 1, transition: 'opacity 0.2s' }}>
              <OverviewStat id="total-edits" className={`stat-display__value${selectedMetric === 'edits' ? ' stat-change' : ''}`} stat={formattedKpis.edits} statMsg="Total Edits" renderZero={true} />
              <OverviewStat id="article-views" className={`stat-display__value${selectedMetric === 'articleViews' ? ' stat-change' : ''}`} stat={formattedKpis.articleViews} statMsg="Article Views" renderZero={true} />
              <OverviewStat id="articles-created" className={`stat-display__value${selectedMetric === 'articlesCreated' ? ' stat-change' : ''}`} stat={formattedKpis.articlesCreated} statMsg="Articles Created" renderZero={true} />
              <OverviewStat id="articles-improved" className={`stat-display__value${selectedMetric === 'articlesImproved' ? ' stat-change' : ''}`} stat={formattedKpis.articlesImproved} statMsg="Articles Improved" renderZero={true} />
              <OverviewStat id="characters-added" className={`stat-display__value${selectedMetric === 'charactersAdded' ? ' stat-change' : ''}`} stat={formattedKpis.charactersAdded} statMsg="Characters Added" renderZero={true} />
              <OverviewStat id="new-editors" className={`stat-display__value${selectedMetric === 'newEditors' ? ' stat-change' : ''}`} stat={formattedKpis.newEditors} statMsg="New Editors" renderZero={true} />
              <OverviewStat id="active-programs" className={`stat-display__value${selectedMetric === 'activePrograms' ? ' stat-change' : ''}`} stat={formattedKpis.activePrograms} statMsg="Active Programs" renderZero={true} />
              <OverviewStat id="active-facilitators" className={`stat-display__value${selectedMetric === 'activeFacilitators' ? ' stat-change' : ''}`} stat={formattedKpis.activeFacilitators} statMsg="Active Facilitators" renderZero={true} />
            </div>

          </>
        )}
      </div>

      {(!loading || stats) && (
        <div style={{ opacity: loading ? 0.6 : 1, transition: 'opacity 0.2s' }}>
          {/* Charts */}
          <div className="container">
            <div className="system-stats__charts">
              <div>
                <div className="system-stats__metric-selector">
                  <label htmlFor="metric-plot-select">Plot metric:</label>
                  <select id="metric-plot-select" value={selectedMetric} onChange={(e) => setSelectedMetric(e.target.value)}>
                    {Object.entries(METRIC_CONFIG).map(([key, config]) => (
                      <option key={key} value={key}>{config.label}</option>
                    ))}
                  </select>
                </div>
                <div className="module">
                  <div className="section-header">
                    <h3>Monthly Activity Trends</h3>
                  </div>
                  <div className="system-stats__chart-canvas">
                    {activeStats.trends && activeStats.trends.length > 0 ? (
                      <canvas ref={trendChartRef} />
                    ) : (
                      <div style={{ padding: '40px', textAlign: 'center', color: '#a0aec0' }}>No trend data available.</div>
                    )}
                  </div>
                </div>
              </div>
              <div>
                <div className="system-stats__metric-selector">
                  <label htmlFor="wiki-metric-plot-select">Plot metric:</label>
                  <select id="wiki-metric-plot-select" value={selectedWikiMetric} onChange={(e) => setSelectedWikiMetric(e.target.value)}>
                    {Object.entries(WIKI_METRIC_CONFIG).map(([key, config]) => (
                      <option key={key} value={key}>{config.label}</option>
                    ))}
                  </select>
                </div>
                <div className="module">
                  <div className="section-header">
                    <h3>Wiki Trends (Top 5)</h3>
                  </div>
                  <div className="system-stats__chart-canvas">
                    {loadingWikiTrends ? (
                      <div className="loading" style={{ padding: '40px', display: 'flex', flexDirection: 'column', justifyContent: 'center', alignItems: 'center' }}>
                        <div className="loading__spinner" />
                        <p style={{ marginTop: '15px', color: '#718096' }}>Loading wiki trends...</p>
                      </div>
                    ) : wikiTrends && wikiTrends.wiki_trends && Object.keys(wikiTrends.wiki_trends).length > 0 ? (
                      <canvas ref={wikiChartRef} />
                    ) : (
                      <div style={{ padding: '40px', textAlign: 'center', color: '#a0aec0' }}>No wiki trend data available.</div>
                    )}
                  </div>
                </div>
              </div>
            </div>

            {/* Wiki Stats Breakdown Table */}
            <div className="module" style={{ marginTop: '20px' }}>
              <div className="section-header">
                <h3>Wiki Stats Breakdown (Top 5)</h3>
              </div>
              <div className="table-responsive">
                <table className="table table--hoverable">
                  <thead>
                    <tr>
                      <th>Wiki</th>
                      <th>Edits</th>
                      <th>Programs</th>
                      <th>Articles Created</th>
                      <th>New Editors</th>
                    </tr>
                  </thead>
                  <tbody>
                    {loadingWikiTrends ? (
                      <tr>
                        <td colSpan="5" style={{ textAlign: 'center', color: '#a0aec0' }}>Loading wiki stats...</td>
                      </tr>
                    ) : wikiTrends && wikiTrends.wiki_stats && wikiTrends.wiki_stats.length > 0 ? (
                      wikiTrends.wiki_stats.map(w => (
                        <tr key={w.name}>
                          <td>{w.name}</td>
                          <td>{w.edits.toLocaleString()}</td>
                          <td>{w.programs.toLocaleString()}</td>
                          <td>{w.articles_created.toLocaleString()}</td>
                          <td>{w.new_editors.toLocaleString()}</td>
                        </tr>
                      ))
                    ) : (
                      <tr>
                        <td colSpan="5" style={{ textAlign: 'center', color: '#a0aec0' }}>No wiki project stats available.</td>
                      </tr>
                    )}
                  </tbody>
                </table>
              </div>
            </div>
          </div>

          {/* Facilitator Leaderboard */}
          <div id="facilitators" className="container">
            <div className="section-header">
              <h3>Facilitator Leaderboard (Top 5)</h3>
            </div>
            <div className="table-responsive">
              <table className="table table--sortable table--hoverable">
                <thead>
                  <tr>
                    <th className={`sortable${sortField === 'username' ? ` ${sortOrder}` : ''}`} onClick={() => handleSort('username')}>
                      Username
                    </th>
                    <th className={`sortable${sortField === 'courses' ? ` ${sortOrder}` : ''}`} onClick={() => handleSort('courses')}>
                      Courses
                    </th>
                    <th className={`sortable${sortField === 'activeCourses' ? ` ${sortOrder}` : ''}`} onClick={() => handleSort('activeCourses')}>
                      Active
                    </th>
                    <th className={`sortable${sortField === 'edits' ? ` ${sortOrder}` : ''}`} onClick={() => handleSort('edits')}>
                      Edits
                    </th>
                    <th className={`sortable${sortField === 'students' ? ` ${sortOrder}` : ''}`} onClick={() => handleSort('students')}>
                      Students
                    </th>
                    <th className={`sortable${sortField === 'newEditors' ? ` ${sortOrder}` : ''}`} onClick={() => handleSort('newEditors')}>
                      New Editors
                    </th>
                    <th className={`sortable${sortField === 'activeInYear' ? ` ${sortOrder}` : ''}`} onClick={() => handleSort('activeInYear')}>
                      Active in Year
                    </th>
                  </tr>
                </thead>
                <tbody>
                  {loadingFacilitators ? (
                    <tr>
                      <td colSpan="7" style={{ textAlign: 'center', color: '#a0aec0' }}>Loading facilitators...</td>
                    </tr>
                  ) : filteredAndSortedFacilitators.length > 0 ? (
                    filteredAndSortedFacilitators.map(f => (
                      <tr key={f.username}>
                        <td>{f.username}</td>
                        <td>{f.courses}</td>
                        <td>{f.activeCourses}</td>
                        <td>{f.edits.toLocaleString()}</td>
                        <td>{f.students}</td>
                        <td>{f.newEditors}</td>
                        <td>{f.activeInYear}</td>
                      </tr>
                    ))
                  ) : (
                    <tr>
                      <td colSpan="7" style={{ textAlign: 'center', color: '#a0aec0' }}>No facilitators found.</td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}
    </>
  );
};

export default SystemStatsHandler;
