/* global vegaEmbed */
import React, { useEffect } from 'react';
import PropTypes from 'prop-types';
import ArticleUtils from '../../../utils/article_utils';

const renderGraph = (id, statsData, bins, labels, days, namespaces) => {
  const vegaSpec = {
    width: 800,
    height: 250,
    padding: { top: 40, left: 70, right: 20, bottom: 50 },

    signals: [
        {
          name: 'namespace',
          value: 'all',
          bind: {
            input: 'select',
            options: ['all'].concat(namespaces),
            name: 'Namespace:',
          },
        },
      ],

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
                        signal: "data('labels')[datum.value].label + ' ' +data('totalByBin')[datum.value].total_by_bin + ' (' + round(data('totalByBin')[datum.value].total_by_bin * 10000 / data('total')[0].total) / 100 + '%)'"
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
          parse: { created_at: 'date', count: 'number', namespace: 'string', bin: 'number' }
        },
        transform: [
          {
            type: 'filter',
            expr: "(namespace === 'all') ? true : datum.namespace === namespace"
          },
          {
            type: 'stack',
            groupby: ['created_at'],
            field: 'count',
            sort: { field: 'bin', order: 'ascending' }
          },
        ]
      },
      {
        name: 'total',
        source: 'data',
        transform: [
          {
            type: 'aggregate',
            ops: ['sum'],
            fields: ['count'],
            as: ['total']
          }
        ]
      },
      {
        name: 'totalByBin',
        source: 'data',
        transform: [
          {
            type: 'aggregate',
            groupby: ['bin'],
            ops: ['sum'],
            fields: ['count'],
            as: ['total_by_bin']
          }
        ]
      },
      {
        name: 'labels',
        values: labels,
        format: {
          type: 'json',
          parse: { label: 'string' }
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
            groupby: 'bin'
          }
        },
        marks: [
          {
            type: 'rect',
            from: { data: 'series' },
            encode: {
              update: {
                interpolate: { value: 'monotone' },
                x: { scale: 'x', field: 'created_at' },
                x2: { scale: 'x', field: 'created_at', offset: 800 / days },
                y: { scale: 'y', field: 'y0' },
                y2: { scale: 'y', field: 'y1' },
                fill: { scale: 'color', field: 'bin' },
                fillOpacity: { value: 1 }
              },
              hover: { fillOpacity: { value: 0.5 } }
            }
          }
        ]
      }
    ]
  };

  vegaEmbed(`#${id}`, vegaSpec, { defaultStyle: true, actions: { source: false } });
};

const ScoresTrendsInBinsGraph = (props) => {
  const id = `ScoresTrendsInBinsGraph${props.id}`;
  // Calculate the number of bins to create labels
  const bins = Math.max(...new Set(props.statsData.map(d => d.bin)));

  const formatLabel = (key) => {
    const start = Math.round((key / bins) * 100) / 100;
    const end = Math.round(((key / bins) + (1 / bins)) * 100) / 100;
    // The last bin has to use a closed interval (']')
    const bracket = Number(key) === bins - 1 ? ']' : ')';
    return { label: `[${start}, ${end}${bracket}:` };
  };

  // Format the labels for the chart
  const legendLabels = Array.from({ length: bins }, (_, i) => i).map(e => formatLabel(e));

  // Calculate number of days in the period
  const days = props.statsData.map(s => new Date(s.created_at).getTime());
  const minDay = Math.min(...days);
  const maxDay = Math.max(...days);
  const numberOfdays = Math.round((maxDay - minDay) / (1000 * 60 * 60 * 24));

  const statsDataWithNamespaces = props.statsData.map((s) => {
    return {
      created_at: s.created_at,
      namespace: ArticleUtils.NamespaceIdMapping[s.namespace],
      bin: s.bin,
      count: s.count
    };
  });
  const namespaces = [...new Set(statsDataWithNamespaces.map(d => d.namespace))];
  useEffect(() => {
    renderGraph(id, statsDataWithNamespaces, bins, legendLabels, numberOfdays, namespaces);
  }, []);
    return (
      <div id={id} />
    );
};

ScoresTrendsInBinsGraph.displayName = 'ScoresTrendsInBinsGraph';
ScoresTrendsInBinsGraph.propTypes = {
  id: PropTypes.string,
  statsData: PropTypes.array,
};

export default ScoresTrendsInBinsGraph;
