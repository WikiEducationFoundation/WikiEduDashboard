/* global vegaEmbed */
import React, { useEffect } from 'react';
import PropTypes from 'prop-types';

const renderGraph = (id, statsData, bins, labels, days) => {
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
        type: 'symbol',
        symbolType: 'square',
        // Force all legends to be displayed
        values: Array.from({ length: bins }, (_, i) => i),
        labelFontSize: 16,
        title: 'Bins',
        titleFontSize: 16,
        titlePadding: 16,
        rowPadding: 4,
        labelLimit: 2000,
        labelOverlap: false,

        encode: {
            labels: {
                update: {
                    text: {
                        signal: "data('labels')[datum.value].label"
                    }
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
          parse: { created_at: 'date', count: 'number', value: 'number' }
        },
        transform: [
          {
            type: 'stack',
            groupby: ['created_at'],
            field: 'count'
          }
        ]
      },
      {
        name: 'labels',
        values: labels,
        format: {
          type: 'json',
          parse: { value: 'string', label: 'string' }
        },
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
        type: 'linear',
        domain: [0, bins],
        range: { scheme: 'reds' },
        nice: true
      },
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
        title: 'Count'
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
            groupby: 'value'
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
                fill: { scale: 'color', field: 'value' }
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
  // Calculate the number of bins to create labels
  const bins = Math.max(...Object.keys(props.countByBin).map(Number));

  useEffect(() => {
    const formatLabel = (key, count, pct) => {
      const start = Math.round((key / bins) * 100) / 100;
      const end = Math.round(((key / bins) + (1 / bins)) * 100) / 100;
      // The last bin has to use a closed interval (']')
      const bracket = Number(key) === bins - 1 ? ']' : ')';
      return `[${start}, ${end}${bracket}: ${count} (${pct}%)`;
    };
    // Format the labels for the chart
    const legendLabels = Object.entries(props.countByBin).map(([key, count]) => {
      const pct = Math.round((count / props.total) * 100);
      return {
        value: key,
        label: formatLabel(key, count, pct),
      };
    });

    // Calculate number of days in the period
    const days = props.statsData.map(s => new Date(s.created_at).getTime());
    const minDay = Math.min(...days);
    const maxDay = Math.max(...days);
    const numberOfdays = Math.round((maxDay - minDay) / (1000 * 60 * 60 * 24));

    renderGraph(id, props.statsData, bins, legendLabels, numberOfdays);
  }, []);
    return (
      <div id={id} />
    );
};

ScoresTrendsGraph.displayName = 'ScoresTrendsGraph';
ScoresTrendsGraph.propTypes = {
  id: PropTypes.string,
  statsData: PropTypes.array,
  countByBin: PropTypes.object,
  total: PropTypes.number,
};

export default ScoresTrendsGraph;
