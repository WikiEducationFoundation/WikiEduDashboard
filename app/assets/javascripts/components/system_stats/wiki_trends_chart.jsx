import React, { useState, useEffect, useRef } from 'react';
import Chart from 'chart.js/auto';

const WIKI_METRIC_KEYS = ['edits', 'programs', 'articles_created', 'new_editors'];

const WIKI_METRIC_I18N_MAP = {
  edits: 'system_stats.tables.edits',
  programs: 'system_stats.tables.programs',
  articles_created: 'system_stats.tables.articles_created',
  new_editors: 'system_stats.tables.new_editors'
};

// Chart.js colors are kept in JS since they're passed as config to the Chart API
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

import { formatMonthLabel } from '../../utils/system_stats_utils';

const WikiTrendsChart = ({ wikiTrends, loading }) => {
  const [selectedWikiMetric, setSelectedWikiMetric] = useState('edits');
  const chartRef = useRef(null);
  const chartInstance = useRef(null);

  useEffect(() => {
    if (loading || !wikiTrends || !wikiTrends.wiki_trends || Object.keys(wikiTrends.wiki_trends).length === 0) return;
    if (!chartRef.current) return;
    if (chartInstance.current) {
      chartInstance.current.destroy();
    }

    const ctx = chartRef.current.getContext('2d');
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

    chartInstance.current = new Chart(ctx, {
      type: 'line',
      data: {
        labels: (wikiTrends.months || []).map(m => formatMonthLabel(m)),
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
              text: I18n.t(WIKI_METRIC_I18N_MAP[selectedWikiMetric])
            },
            grid: {
              color: '#e2e8f0'
            }
          }
        }
      }
    });

    return () => {
      if (chartInstance.current) {
        chartInstance.current.destroy();
      }
    };
  }, [wikiTrends, selectedWikiMetric, loading]);

  return (
    <div>
      <div className="system-stats__metric-selector">
        <label htmlFor="wiki-metric-plot-select">{I18n.t('system_stats.charts.plot_metric')}</label>
        <select id="wiki-metric-plot-select" value={selectedWikiMetric} onChange={(e) => setSelectedWikiMetric(e.target.value)}>
          {WIKI_METRIC_KEYS.map(key => (
            <option key={key} value={key}>{I18n.t(WIKI_METRIC_I18N_MAP[key])}</option>
          ))}
        </select>
      </div>
      <div className="module">
        <div className="section-header">
          <h2>{I18n.t('system_stats.charts.wiki_trends')}</h2>
        </div>
        <div className="system-stats__chart-canvas">
          {loading ? (
            <div className="loading system-stats__loading-container">
              <div className="loading__spinner" />
              <p className="system-stats__loading-text">{I18n.t('system_stats.loading.wiki_trends')}</p>
            </div>
          ) : wikiTrends && wikiTrends.wiki_trends && Object.keys(wikiTrends.wiki_trends).length > 0 ? (
            <canvas ref={chartRef} />
          ) : (
            <div className="system-stats__empty-state">{I18n.t('system_stats.empty.no_wiki_trend_data')}</div>
          )}
        </div>
      </div>
    </div>
  );
};

export default WikiTrendsChart;
