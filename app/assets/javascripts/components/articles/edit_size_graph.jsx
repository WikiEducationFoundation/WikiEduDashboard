/* global vegaEmbed */
import React from 'react';
import createReactClass from 'create-react-class';
import PropTypes from 'prop-types';

const EditSizeGraph = createReactClass({
  displayName: 'EditSizeGraph',

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
            data: 'characters_edited',
            field: 'date',
            sort: { field: 'date', op: 'min' }
          },
          range: [0, this.props.graphWidth],
          round: true
        },
        {
          name: 'y',
          type: 'linear',
          domain: {
            data: 'characters_edited',
            field: 'characters'
          },
          range: [this.props.graphHeight, 0],
          round: true,
          nice: true,
          zero: true
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
          title: I18n.t('metrics.characters')
        }
      ],
      // ///////////////
      // Data Sources //
      // ///////////////
      data: [
        {
          name: 'characters_edited',
          values: this.props.articleData,
          format: { type: 'json', parse: { date: 'date', characters: 'number' } },
          transform: [{
            type: 'filter',
            expr: 'datum.date !== null && !isNaN(datum.date) && datum.characters!== null && !isNaN(datum.characters) && datum.characters !== 0'
          }
          ]
        }
      ],
      // //////////////
      // Mark layers //
      // //////////////
      marks: [
        {
          type: 'rule',
          encode: {
            update: {
              x: { value: 0 },
              x2: { value: this.props.graphWidth },
              y: { scale: 'y', value: 0 },
              stroke: { value: '#000000' },
              strokeWidth: { value: 1 },
              strokeOpacity: { value: 0.5 }
            }
          }
        },
        {
          type: 'rule',
          from: {
            data: 'characters_edited',
            transform: [{ type: 'sort', by: '-date' }]
          },
          encode:
          {
            update: {
              x: { scale: 'x', field: 'date' },
              y: { scale: 'y', field: 'characters' },
              y2: { scale: 'y', value: 0 },
              strokeWidth: { value: 2 },
              strokeOpacity: { value: 0.3 },
              stroke: [
                {
                  test: 'datum.characters > 0',
                  value: '#0000ff'
                },
                { value: '#ff0000' }
              ]
            }
          }
        },
        {
          name: 'circle_marks',
          type: 'symbol',
          from: {
            data: 'characters_edited',
            transform: [{ type: 'sort', by: '-date' }]
          },
          encode: { enter: {
            orient: { value: 'vertical' },
            opacity: { value: 0.5 }
          },
            update: {
              x: { scale: 'x', field: 'date' },
              y: { scale: 'y', field: 'characters' },
              y2: { scale: 'y' },
              size: { value: 100 },
              shape: { value: 'circle' },
              fill: [
                {
                  test: 'datum.characters > 0',
                  value: '#0000ff'
                },
                { value: '#ff0000' }
              ]
            }
          }
        }
      ]
    };

    // emded the visualization in the container with id vega-graph-article_id
    vegaEmbed(`#${this.props.graphid}`, vegaSpec, { actions: false }); // Callback receiving View instance and parsed Vega spec
  },


  render() {
    return (
      <div>
        <div id={this.props.graphid} />
      </div>
    );
  }
});

export default EditSizeGraph;
