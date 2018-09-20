/* global vegaEmbed */
import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';

const exampleData = [
  { ores_before: 31.6881, ores_after: 32.4583 },
  { ores_before: 16.8636, ores_after: 23.0991 },
  { ores_before: 4.91801, ores_after: 17.0304 },
  { ores_before: 23.4096, ores_after: 29.25 },
  { ores_before: 17.5069, ores_after: 26.3541 },
  { ores_before: 24.7242, ores_after: 28.4812 },
  { ores_before: 11.3788, ores_after: 23.0004 },
  { ores_before: 12.7192, ores_after: 26.9184 },
  { ores_before: 10.8967, ores_after: 23.5062 },
  { ores_before: 23.3852, ores_after: 23.712 },
  { ores_before: 17.5069, ores_after: 22.6992 },
  { ores_before: 23.5062, ores_after: 26.154 }
];

const CourseQualityProgressGraph = createReactClass({
  displayName: 'CourseQualityProgressGraph',

  propTypes: {
    graphid: PropTypes.string,
    graphWidth: PropTypes.number,
    graphHeight: PropTypes.number,
    articleData: PropTypes.array
  },

  componentDidMount() {
    this.renderGraph();
  },

  renderGraph() {
    const vegaSpec = {
      width: 1000,
      height: 200,
      padding: 5,

      signals: [
        { name: 'bandwidth', value: 1 },
        { name: 'steps', value: 1000 },
        { name: 'method', value: 'pdf' }
      ],

      data: [
        {
          name: 'points',
          values: exampleData
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
                mean: { signal: "data('before')[0].mean" },
                stdev: { signal: "data('before')[0].stdev" }
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
          domain: { data: 'points', fields: ['ores_before', 'ores_after'] },
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

      axes: [
        { orient: 'bottom', scale: 'xscale', zindex: 1 }
      ],

      legends: [
        { orient: 'top-left', fill: 'color', offset: 0, zindex: 1 }
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
          type: 'rect',
          from: { data: 'points' },
          encode: {
            enter: {
              x: { scale: 'xscale', field: 'ores_before' },
              width: { value: 1 },
              y: { value: 25, offset: { signal: 'height' } },
              height: { value: 5 },
              fill: { value: 'steelblue' },
              fillOpacity: { value: 0.4 }
            }
          }
        }
      ]
    };
    vegaEmbed(`#${this.props.graphid}`, vegaSpec, { actions: false });
  },

  render() {
    return (
      <div>
        <div id={this.props.graphid} />
      </div>
    );
  }
});

export default CourseQualityProgressGraph;
