/* global vegaEmbed */
import React, { useEffect } from 'react';
import PropTypes from 'prop-types';

const renderGraph = (statsData, pageTypes, labels) => {
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
        title: 'Page type',
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
          parse: { created_at: 'date', count: 'number', page_type: 'string' }
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
        domain: { data: 'data', field: 'page_type' },
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
        title: 'Date',
        format: '%b %d %Y',
        labelAngle: -20,
        labelOverlap: 'greedy',
        labelPadding: 10
      },
      {
        scale: 'y',
        orient: 'left',
        title: 'AI alerts count'
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
            groupby: 'page_type'
          }
        },
        marks: [
          {
            type: 'area',
            from: { data: 'series' },
            encode: {
              enter: {
                interpolate: { value: 'monotone' },
                x: { scale: 'x', field: 'created_at' },
                y: { scale: 'y', field: 'y0' },
                y2: { scale: 'y', field: 'y1' },
                fill: { scale: 'color', field: 'page_type' }
              },
              update: { fillOpacity: { value: 1 } },
              hover: { fillOpacity: { value: 0.5 } }
            }
          }
        ]
      }
    ]
  };

  vegaEmbed('#AlertsTrendsGraph', vegaSpec, { defaultStyle: true, actions: { source: false } });
};

const AlertsTrendsGraph = (props) => {
  useEffect(() => {
    // Format the labels for the chart
    const legendLabels = Object.entries(props.countByPage).map(([key, count]) => {
      const pct = Math.round((count / props.total) * 100);
      return {
        page_type: key,
        label: `${key}: ${count} (${pct}%)`
      };
    });

    renderGraph(props.statsData, legendLabels.map(e => e.page_type), legendLabels.map(e => e.label));
  }, []);
    return (
      <div id="AlertsTrendsGraph" />
    );
};

AlertsTrendsGraph.displayName = 'AlertsTrendsGraph';
AlertsTrendsGraph.propTypes = {
  statsData: PropTypes.array,
  countByPage: PropTypes.object,
  total: PropTypes.number,
};

export default AlertsTrendsGraph;
