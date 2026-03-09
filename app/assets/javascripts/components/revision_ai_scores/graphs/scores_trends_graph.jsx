/* global vegaEmbed */
import React, { useEffect } from 'react';
import PropTypes from 'prop-types';
import ArticleUtils from '../../../utils/article_utils';

const renderGraph = (id, statsData, pageTypes, labels, days) => {
  const vegaSpec = {
    width: 800,
    height: 250,
    padding: { top: 40, left: 70, right: 20, bottom: 50 },

    // //////////
    // Legends //
    // //////////
    legends: [
      {
        fill: 'color',
        labelFontSize: 16,
        title: 'Namespaces',
        titleFontSize: 16,
        titlePadding: 16,
        rowPadding: 8,
        labelLimit: 2000,
        encode: {
          labels: {
            update: {
              text: { scale: 'legend_scale', field: 'value' }
            }
          }
        }
      }
    ],

    // ///////////////
    // Data Sources //
    // ///////////////
    data: [
      {
        name: 'data',
        values: statsData,
        format: {
          type: 'json',
          parse: { created_at: 'date', count: 'number', namespace: 'string', bin: 'number' }
        },
        transform: [
          {
            type: 'stack',
            groupby: ['created_at'],
            field: 'count'
          }
        ]
      }
    ],

    // //////////////////
    // Scales and Axes //
    // //////////////////
    scales: [
      {
        name: 'x',
        type: 'time',
        domain: { data: 'data', field: 'created_at' },
        range: 'width'
      },
      {
        name: 'y',
        type: 'linear',
        domain: { data: 'data', field: 'y1' },
        range: 'height',
        nice: true,
        zero: true
      },
      {
        name: 'color',
        type: 'ordinal',
        domain: { data: 'data', field: 'namespace' },
        range: 'category'
      },
      {
        name: 'legend_scale',
        type: 'ordinal',
        domain: pageTypes,
        range: labels
      }
    ],

    axes: [
      {
        scale: 'x',
        orient: 'bottom',
        title: 'Revision creation date',
        format: '%b %d %Y',
        tickCount: 'day',
        labelAngle: -20,
        labelOverlap: 'greedy',
        labelPadding: 10
      },
      {
        scale: 'y',
        orient: 'left',
        title: 'Check count'
      }
    ],

    // //////////////
    // Mark layers //
    // //////////////
    marks: [
      {
        type: 'group',
        from: {
          facet: {
            name: 'series',
            data: 'data',
            groupby: 'namespace'
          }
        },
        marks: [
          {
            type: 'rect',
            from: { data: 'series' },
            encode: {
              enter: {
                interpolate: { value: 'monotone' },
                x: { scale: 'x', field: 'created_at' },
                x2: { scale: 'x', field: 'created_at', offset: 800 / days },
                y: { scale: 'y', field: 'y0' },
                y2: { scale: 'y', field: 'y1' },
                fill: { scale: 'color', field: 'namespace' }
              },
              update: { fillOpacity: { value: 1 } },
              hover: { fillOpacity: { value: 0.5 } }
            }
          }
        ]
      }
    ]
  };

  vegaEmbed(`#${id}`, vegaSpec, { defaultStyle: true, actions: { source: false } });
};

const ScoresTrendsGraph = (props) => {
  const id = `ScoresTrendsGraph${props.id}`;
  // Calculate count by page type
  const countByPage = props.statsData.reduce((acc, s) => {
    acc[s.namespace] = (acc[s.namespace] || 0) + s.count;
    return acc;
  }, {});

  const total = props.statsData.reduce((acc, s) => {
    return acc + s.count;
  }, 0);

  // Format the labels for the chart
  const legendLabels = Object.entries(countByPage).map(([key, count]) => {
    const pct = ((count / total) * 100).toFixed(2);
    return {
      value: key,
      label: `${ArticleUtils.NamespaceIdMapping[key]}: ${count} (${pct}%)`
    };
  });

  // Calculate number of days in the period
  const days = props.statsData.map(s => new Date(s.created_at).getTime());
  const minDay = Math.min(...days);
  const maxDay = Math.max(...days);
  const numberOfdays = Math.round((maxDay - minDay) / (1000 * 60 * 60 * 24));

  useEffect(() => {
    renderGraph(id, props.statsData, legendLabels.map(e => e.value), legendLabels.map(e => e.label), numberOfdays);
  }, []);
    return (
      <div id={id} />
    );
};

ScoresTrendsGraph.displayName = 'ScoresTrendsGraph';
ScoresTrendsGraph.propTypes = {
  id: PropTypes.string,
  statsData: PropTypes.array,
};

export default ScoresTrendsGraph;
