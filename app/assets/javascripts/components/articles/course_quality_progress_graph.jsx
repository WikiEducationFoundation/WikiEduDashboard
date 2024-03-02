/* global vegaEmbed */
import React, { useEffect } from 'react';
import PropTypes from 'prop-types';


const CourseQualityProgressGraph = ({ graphid, graphWidth, graphHeight, articleData }) => {
  useEffect(() => {
    renderGraph();
  }, [articleData]);

  const renderGraph = () => {
    if (articleData.length === 0) {
      return;
    }

    const max_bytes_added = Math.max(
      ...articleData.map(o => o.bytes_added),
      0
    );
    const max_score = Math.max(
      ...articleData.map(o => o.ores_after - o.ores_before),
      0
    );
    const vegaSpec = {
      width: graphWidth,
      height: graphHeight,
      padding: 5,
      signals: [
        { name: 'bandwidth', value: 1 },
        { name: 'steps', value: 1000 },
        { name: 'method', value: 'pdf' },
        {
          name: 'articles',
          value: 'both',
          bind: {
            input: 'radio',
            options: ['new', 'existing', 'both'],
            name: 'Articles:',
          },
        },
        {
          name: 'bytes_added',
          value: 0,
          bind: {
            input: 'range',
            min: 0,
            max: max_bytes_added,
            name: 'Minimum bytes added:',
          },
        },
        {
          name: 'score',
          value: 0,
          bind: {
            input: 'range',
            min: 0,
            max: max_score,
            name: 'Minimum change in score:',
          },
        },
        {
          name: 'articleCount',
          value: 0,
          update: "'Article count: ' + data('points').length",
        },
        {
          name: 'mean_ores_before',
          value: 0,
          update:
            "'Mean score before: ' + format(data('mean_before')[0].mean_ores_before, '.1f')"
        },
        {
          name: 'mean_ores_after',
          value: 0,
          update:
            "'Mean score after: ' + format(data('mean_after')[0].mean_ores_after, '.1f')"
        },
      ],

      data: [
        {
          name: 'points',
          values: articleData,
          transform: [
            { // Filter based on the [new / existing / both] selection
              type: 'filter',
              expr:
                "(articles === 'both') ? true : (articles === 'new' ? (datum.ores_before === 0) : (datum.ores_before > 0))"
            },
            { // Filter based on the 'Minimum bytes added' slider. The minimum bytes added is zero, so by default no articles are filtered out.
              type: 'filter',
              expr: 'datum.bytes_added >= bytes_added'
            },
            { // Filter based on the 'Minimum change in score' slider. This can be negative, so we treat the default 0 position as no filter.
              type: 'filter',
              expr: '(score === 0) ? true : (datum.ores_after - datum.ores_before) >= score'
            }
          ]
        },
        {
          name: 'mean_before',
          source: 'points',
          transform: [
            {
              type: 'aggregate',
              fields: ['ores_before'],
              ops: ['mean'],
            }
          ]
        },
        {
          name: 'mean_after',
          source: 'points',
          transform: [
            {
              type: 'aggregate',
              fields: ['ores_after'],
              ops: ['mean'],
            }
          ]
        },
        {
          name: 'before',
          source: 'points',
          transform: [
            {
              type: 'aggregate',
              fields: ['ores_before', 'ores_before'],
              ops: ['mean', 'stdev'],
              as: ['mean', 'stdev']
            }
          ]
        },
        {
          name: 'after',
          source: 'points',
          transform: [
            {
              type: 'aggregate',
              fields: ['ores_after', 'ores_after'],
              ops: ['mean', 'stdev'],
              as: ['mean', 'stdev']
            }
          ]
        },
        {
          name: 'density',
          source: 'points',
          transform: [
            {
              type: 'density',
              extent: { signal: "domain('xscale')" },
              steps: { signal: 'steps' },
              method: { signal: 'method' },
              distribution: {
                function: 'kde',
                field: 'ores_before',
                bandwidth: { signal: 'bandwidth' }
              }
            }
          ]
        },
        {
          name: 'density_after',
          source: 'points',
          transform: [
            {
              type: 'density',
              extent: { signal: "domain('xscale')" },
              steps: { signal: 'steps' },
              method: { signal: 'method' },
              distribution: {
                function: 'kde',
                field: 'ores_after',
                bandwidth: { signal: 'bandwidth' }
              }
            }
          ]
        },
        {
          name: 'normal',
          transform: [
            {
              type: 'density',
              extent: { signal: "domain('xscale')" },
              steps: { signal: 'steps' },
              method: { signal: 'method' },
              distribution: {
                function: 'normal',
                mean: { signal: "data('before')[0] && data('before')[0].mean" },
                stdev: {
                  signal: "data('before')[0] && data('before')[0].stdev"
                }
              }
            }
          ]
        }
      ],
      scales: [
        {
          name: 'xscale',
          type: 'linear',
          range: 'width',
          domain: [0, 100],
          nice: true
        },
        {
          name: 'yscale',
          type: 'linear',
          range: 'height',
          round: true,
          domain: {
            fields: [
              { data: 'density', field: 'density' },
              { data: 'density', field: 'density_after' }
            ]
          }
        },
        {
          name: 'color',
          type: 'ordinal',
          domain: ['before', 'after'],
          range: ['#676eb4', '#359178']
        }
      ],

      axes: [{ orient: 'bottom', scale: 'xscale', zindex: 1 }],

      legends: [
        { orient: 'right', fill: 'color', offset: 0, zindex: 1 },
        {
          orient: 'right',
          fill: 'color',
          offset: -15,
          zindex: 1,
          values: [
            {
              signal: 'articleCount'
            },
            {
              signal: 'mean_ores_before'
            },
            {
              signal: 'mean_ores_after'
            }
          ]
        }
      ],
      marks: [
        {
          type: 'area',
          from: { data: 'density' },
          encode: {
            update: {
              x: { scale: 'xscale', field: 'value' },
              y: { scale: 'yscale', field: 'density' },
              y2: { scale: 'yscale', value: 0 },
              fill: { signal: "scale('color', 'before')" },
              fillOpacity: { value: 0.5 }
            }
          }
        },
        {
          type: 'area',
          from: { data: 'density_after' },
          encode: {
            update: {
              x: { scale: 'xscale', field: 'value' },
              y: { scale: 'yscale', field: 'density' },
              y2: { scale: 'yscale', value: 0 },
              fill: { signal: "scale('color', 'after')" },
              fillOpacity: { value: 0.5 }
            }
          }
        },
        {
          type: 'symbol',
          from: { data: 'points' },
          encode: {
            enter: {
              shape: { value: 'circle' },
              x: { scale: 'xscale', field: 'ores_before' },
              size: { value: 200 },
              y: { value: 25, offset: { signal: 'height' } },
              height: { value: 5 },
              fill: { signal: "scale('color', 'before')" },
              fillOpacity: { value: 0.4 },
              stroke: { signal: "scale('color', 'before')" },
              tooltip: { signal: "{'Before': datum.article_title}" }
            }
          }
        },
        {
          type: 'symbol',
          from: { data: 'points' },
          encode: {
            enter: {
              shape: { value: 'circle' },
              x: { scale: 'xscale', field: 'ores_after' },
              size: { value: 200 },
              y: { value: 25, offset: { signal: 'height' } },
              height: { value: 5 },
              fill: { signal: "scale('color', 'after')" },
              fillOpacity: { value: 0.4 },
              stroke: { signal: "scale('color', 'after')" },
              tooltip: { signal: "{'After': datum.article_title}" }
            }
          }
        }
      ]
    };
    vegaEmbed(`#${graphid}`, vegaSpec, {
      defaultStyle: true,
      actions: { source: false },
    });
  };

  return (
    <div>
      <div id={graphid} />
    </div>
  );
};

CourseQualityProgressGraph.propTypes = {
  graphid: PropTypes.string,
  graphWidth: PropTypes.number,
  graphHeight: PropTypes.number,
  articleData: PropTypes.array,
};

export default CourseQualityProgressGraph;
