/* global vegaEmbed */
import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';

const ReferencesGraph = createReactClass({
  displayName: 'ReferencesGraph',

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
    const value = Math.max(
      ...this.props.articleData.map(o => o.refs),
    0
    );
    let max_refs = value;

    if (value < 8) {
      max_refs = 8;
    }

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
            data: 'references_added',
            field: 'date',
            sort: { field: 'date', op: 'min' }
          },
          range: 'width',
          round: true
        },
        {
          name: 'y',
          type: 'linear',
          range: 'height',
          nice: true,
          zero: true,
          domain: [0, max_refs, 0, max_refs]
        },
        {
          name: 'color',
          type: 'ordinal',
          range: 'category',
          domain: { data: 'references_added', field: 'c' }
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
          title: I18n.t('articles.references')
        }
      ],
      // ///////////////
      // Data Sources //
      // ///////////////
      data: [
        {
          name: 'references_added',
          values: this.props.articleData,
          format: { type: 'json', parse: { date: 'date', refs: 'number' } },
          transform: [{
            type: 'filter',
            expr: 'datum.date !== null && !isNaN(datum.date) && datum.refs !== null && !isNaN(datum.refs)'
          }]
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
              data: 'references_added',
              groupby: 'c'
            }
          },
          marks: [
            {
              type: 'line',
              from: { data: 'references_added' },
              encode: {
                enter: {
                  x: { scale: 'x', field: 'date' },
                  y: { scale: 'y', field: 'refs' },
                  stroke: { scale: 'color', field: 'c' },
                  strokeWidth: { value: 4 }
                },
                update: {
                  fillOpacity: { value: 1 }
                },
                hover: {
                  fillOpacity: { value: 0.5 }
                }
              }
            }
          ]
        }
      ]
    };

    // emded the visualization in the container with id vega-graph-article_id
    vegaEmbed(`#${this.props.graphid}`, vegaSpec, { defaultStyle: true, actions: { source: false } });
  },


  render() {
    return (
      <div>
        <div id={this.props.graphid} />
      </div>
    );
  }
});

export default ReferencesGraph;
