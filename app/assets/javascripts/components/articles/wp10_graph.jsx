/* global vegaEmbed */
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

  componentDidMount() {
    this.renderGraph();
  },

  renderGraph() {
    const vegaSpec = {
      width: this.props.graphWidth,
      height: this.props.graphHeight,
      padding: 5,
      // //////////////////
      // Scales and Axes //
      // //////////////////
      scales: [
        {
          name: 'x',
          type: 'time',
          domain: {
            data: 'wp10_scores',
            field: 'date',
            sort: { field: 'date', op: 'min' }
          },
          range: 'width',
          round: true
        },
        {
          name: 'y',
          type: 'linear',
          domain: [0, 100, 0, 100],
          range: 'height',
          round: true,
          nice: true,
          zero: false
        }
      ],
      axes: [
        {
          orient: 'bottom',
          scale: 'x',
          grid: true,
          ticks: true,
          title: 'Date'
        },
        {
          orient: 'left',
          scale: 'y',
          format: 's',
          grid: true,
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
            expr: 'datum.date !== null && !isNaN(datum.date) && datum.wp10 !== null && !isNaN(datum.wp10)'
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
            data: 'wp10_scores'
          },
          encode: { enter: {
            orient: { value: 'vertical' },
            x: { scale: 'x', field: 'date' },
            y: { scale: 'y', field: 'wp10' },
            y2: { scale: 'y', value: 0 },
            fill: { value: '#676EB4' },
            opacity: { value: 0.7 },
            interpolate: { value: 'step-after' }
          } }
        },
        // Revision point marks
        {
          name: 'circle_marks',
          type: 'symbol',
          from: {
            data: 'wp10_scores'
          },
          encode: {
            enter: {
              x: { scale: 'x', field: 'date' },
              y: { scale: 'y', field: 'wp10' },
              size: { value: 100 },
              shape: { value: 'circle' },
              fill: { value: '#359178' },
              opacity: { value: 0.7 },
              tooltip: { field: 'username' }
            },
            hover: { fill: { value: '#333' }, opacity: { value: 1 } },
            update: {
              fill: { value: '#359178' },
              opacity: { value: 0.7 }
            }
          }
        },

      ],

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

export default Wp10Graph;
