import React, { useState, useEffect, useRef } from 'react';
import Chart from 'chart.js/auto';

const METRIC_KEYS = [
  'edits', 'articleViews', 'articlesCreated', 'articlesImproved',
  'charactersAdded', 'newEditors', 'activePrograms', 'activeFacilitators'
];

const METRIC_I18N_MAP = {
  edits: 'system_stats.kpis.total_edits',
  articleViews: 'system_stats.kpis.article_views',
  articlesCreated: 'system_stats.kpis.articles_created',
  articlesImproved: 'system_stats.kpis.articles_improved',
  charactersAdded: 'system_stats.kpis.characters_added',
  newEditors: 'system_stats.kpis.new_editors',
  activePrograms: 'system_stats.kpis.active_programs',
  activeFacilitators: 'system_stats.kpis.active_facilitators'
};

// Chart.js colors are kept in JS since they're passed as config to the Chart API
const METRIC_COLORS = {
  edits: { color: '#38a169', bg: 'rgba(56, 161, 105, 0.1)' },
  articleViews: { color: '#e53e3e', bg: 'rgba(229, 62, 62, 0.1)' },
  articlesCreated: { color: '#3182ce', bg: 'rgba(49, 130, 206, 0.1)' },
  articlesImproved: { color: '#805ad5', bg: 'rgba(128, 90, 213, 0.1)' },
  charactersAdded: { color: '#dd6b20', bg: 'rgba(221, 107, 32, 0.1)' },
  newEditors: { color: '#319795', bg: 'rgba(49, 151, 149, 0.1)' },
  activePrograms: { color: '#d69e2e', bg: 'rgba(214, 158, 46, 0.1)' },
  activeFacilitators: { color: '#4a5568', bg: 'rgba(74, 85, 104, 0.1)' }
};

import { formatMonthLabel } from '../../utils/system_stats_utils';

const MonthlyActivityChart = ({ trends }) => {
  const [selectedMetric, setSelectedMetric] = useState('edits');
  const chartRef = useRef(null);
  const chartInstance = useRef(null);

  useEffect(() => {
    if (!trends || trends.length === 0) return;
    if (chartInstance.current) {
      chartInstance.current.destroy();
    }

    const ctx = chartRef.current.getContext('2d');
    const colors = METRIC_COLORS[selectedMetric];
    const metricLabel = I18n.t(METRIC_I18N_MAP[selectedMetric]);

    chartInstance.current = new Chart(ctx, {
      type: 'line',
      data: {
        labels: trends.map(t => formatMonthLabel(t.month)),
        datasets: [
          {
            label: metricLabel,
            data: trends.map(t => t[selectedMetric]),
            borderColor: colors.color,
            backgroundColor: colors.bg,
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
              text: metricLabel
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
  }, [trends, selectedMetric]);

  return (
    <div>
      <div className="system-stats__metric-selector">
        <label htmlFor="metric-plot-select">{I18n.t('system_stats.charts.plot_metric')}</label>
        <select id="metric-plot-select" value={selectedMetric} onChange={(e) => setSelectedMetric(e.target.value)}>
          {METRIC_KEYS.map(key => (
            <option key={key} value={key}>{I18n.t(METRIC_I18N_MAP[key])}</option>
          ))}
        </select>
      </div>
      <div className="module">
        <div className="section-header">
          <h2>{I18n.t('system_stats.charts.monthly_trends')}</h2>
        </div>
        <div className="system-stats__chart-canvas">
          {trends && trends.length > 0 ? (
            <canvas ref={chartRef} />
          ) : (
            <div className="system-stats__empty-state">{I18n.t('system_stats.empty.no_trend_data')}</div>
          )}
        </div>
      </div>
    </div>
  );
};

export default MonthlyActivityChart;
