/* global vg */
import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';

const Wp10Graph = createReactClass({
  displayName: 'Wp10Graph',

  propTypes: {
    graphid: PropTypes.string,
    graphWidth: PropTypes.number,
    graphHeight: PropTypes.number,
    articleData: PropTypes.array
  },

  renderGraph() {
    const vegaSpec = {
      width: this.props.graphWidth,
      height: this.props.graphHeight,
      padding: { top: 40, left: 70, right: 20, bottom: 35 },
      // //////////////////
      // Scales and Axes //
      // //////////////////
      scales: [
        {
          name: 'x',
          type: 'time',
          domain: {
            fields: [{
              data: 'wp10_scores',
              field: 'date',
              sort: { field: 'date', op: 'min' }
            }]
          },
          rangeMin: 0,
          rangeMax: this.props.graphWidth,
          round: true
        },
        {
          name: 'y',
          type: 'linear',
          domain: [0, 100, 0, 100],
          rangeMin: this.props.graphHeight,
          rangeMax: 0,
          round: true,
          nice: true,
          zero: false
        }
      ],
      axes: [
        {
          type: 'x',
          scale: 'x',
          grid: true,
          layer: 'back',
          ticks: 5,
          title: 'Date',
          properties: {
            labels: {
              text: { template: '{{datum["data"] | time:\'%b %d\'}}' },
              angle: { value: 0 }
            }
          }
        },
        {
          type: 'y',
          scale: 'y',
          format: 's',
          grid: true,
          layer: 'back',
          offset: 10,
          title: I18n.t('articles.wp10')
        }
      ],
      // ///////////////
      // Data Sources //
      // ///////////////
      data: [
        {
          name: 'wp10_scores',
          values: this.props.articleData,
          format: { type: 'json', parse: { date: 'date', wp10: 'number' } },
          transform: [{
            type: 'filter',
            test: 'datum.date !== null && !isNaN(datum.date) && datum.wp10 !== null && !isNaN(datum.wp10)'
          }]
        }
      ],
      // //////////////
      // Mark layers //
      // //////////////
      marks: [
        // Step graph fill area below scores
        {
          name: 'area_marks',
          type: 'area',
          from: {
            data: 'wp10_scores',
            transform: [{ type: 'sort', by: '-date' }]
          },
          properties: { enter: {
            orient: { value: 'vertical' },
            x: { scale: 'x', field: 'date' },
            y: { scale: 'y', field: 'wp10' },
            y2: { scale: 'y', value: 0 },
            fill: { value: '#676EB4' },
            opacity: { value: 0.7 },
            interpolate: { value: 'step-before' }
          } }
        },
        // Revision point marks
        {
          name: 'circle_marks',
          type: 'symbol',
          from: {
            data: 'wp10_scores',
            transform: [{ type: 'sort', by: '-date' }]
          },
          properties: {
            enter: {
              x: { scale: 'x', field: 'date' },
              y: { scale: 'y', field: 'wp10' },
              size: { value: 100 },
              shape: { value: 'circle' },
              fill: { value: '#359178' },
              opacity: { value: 0.7 }
            },
            update: {
              fill: {
                rule: [
                  {
                    predicate: { name: 'ifRevisionDetails', id: { field: '_id' } },
                    value: '#333',
                  },
                  { value: '#359178' }
                ]
              }
            }
          }
        },
        // Labels on revision mouseover
        {
          name: 'revision_detail_marks',
          type: 'text',
          properties: {
            enter: {
              x: { value: 70 },
              y: { value: -15 },
              align: { value: 'center' },
              fill: { value: '#333' },
              fontSize: { value: 28 }
            },
            update: {
              text: { signal: 'revisionDetails.username' },
              fillOpacity: {
                rule: [
                  {
                    predicate: { name: 'ifRevisionDetails', id: { value: null } },
                    value: 0
                  },
                  { value: 1 }
                ]
              }
            }
          }
        }
      ],
      // ///////////////
      // Interactions //
      // ///////////////
      signals: [
        {
          name: 'revisionDetails',
          init: {},
          streams: [
            { type: 'symbol:mouseover', expr: 'datum' },
            { type: 'symbol:mouseout', expr: '{}' }
          ]
        }
      ],
      predicates: [
        {
          name: 'ifRevisionDetails',
          type: '==',
          operands: [{ signal: 'revisionDetails._id' }, { arg: 'id' }]
        }
      ]
    };

    const embedSpec = {
      mode: 'vega',
      spec: vegaSpec,
      actions: false
    };
    vg.embed(`#${this.props.graphid}`, embedSpec);
  },

  render() {
    this.renderGraph();
    return (
      <div>
        <div id={this.props.graphid} />
      </div>
    );
  }
});

export default Wp10Graph;
