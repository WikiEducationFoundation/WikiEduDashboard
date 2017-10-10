/* global vg */
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
              data: 'characters_edited',
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
          domain: {
            data: 'characters_edited',
            field: 'characters'
          },
          rangeMin: this.props.graphHeight,
          rangeMax: 0,
          round: true,
          nice: true,
          zero: true
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
              text: { template: '{{datum["data"] | time:\'%b\'%d/%y\'}}' },
              angle: { value: 0 },
              fontSize: { value: 9 }
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
            test: 'datum.date !== null && !isNaN(datum.date) && datum.characters!== null && !isNaN(datum.characters) && datum.characters !== 0'
          }
          ]
        }
      ],
      // //////////////
      // Mark layers //
      // //////////////
      marks: [
        {
          type: "rule",
          properties: {
            update: {
              x: { value: 0 },
              x2: { value: this.props.graphWidth },
              y: { scale: "y", value: 0 },
              stroke: { value: "#000000" },
              strokeWidth: { value: 1 },
              strokeOpacity: { value: 0.5 }
            }
          }
        },

        {
          type: "rule",
          from: {
            data: "characters_edited",
            transform: [{ type: 'sort', by: '-date' }]
          },
          properties:
          {
            update: {
              x: { scale: "x", field: "date" },
              y: { scale: "y", field: "characters" },
              y2: { scale: "y", value: 0 },
              strokeWidth: { value: 2 },
              strokeOpacity: { value: 0.3 },
              stroke: [
                {
                  test: "datum.characters > 0",
                  value: "#0000ff"
                },
                { value: "#ff0000" }
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
          properties: { enter: {
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
                  test: "datum.characters > 0",
                  value: '#0000ff'
                },
                { value: '#ff0000' }
              ]
            }
          }
        },
        {
          type: 'text',
          from: {
            data: 'characters_edited'
          },
          properties: {
            enter: {
              x: { signal: "width", mult: 0.68 },
              y: { value: -10 },
              text: { template: "Additions" },
              fill: { value: "#0000ff" },
              fontSize: { value: 13 },
              align: { value: "right" },
              fillOpacity: { value: 0.2 }
            }
          }
        },
        {
          type: 'text',
          from: {
            data: 'characters_edited'
          },
          properties: {
            enter: {
              x: { signal: "width", mult: 0.73 },
              y: { value: -10 },
              text: { template: "and" },
              fill: { value: "#A9A9A9" },
              fontSize: { value: 13 },
              align: { value: "right" },
              fillOpacity: { value: 1 }
            }
          }
        },
        {
          type: 'text',
          from: {
            data: 'characters_edited'
          },
          properties: {
            enter: {
              x: { signal: "width", mult: 0.86 },
              y: { value: -10 },
              text: { template: "Deletions" },
              fill: { value: "#ff0000" },
              fontSize: { value: 13 },
              align: { value: "right" },
              fillOpacity: { value: 0.2 }
            }
          }
        },
        {
          type: 'text',
          from: {
            data: 'characters_edited'
          },
          properties: {
            enter: {
              x: { signal: "width", mult: 0.99 },
              y: { value: -10 },
              text: { template: "over time" },
              fill: { value: "#A9A9A9" },
              fontSize: { value: 13 },
              align: { value: "right" },
              fillOpacity: { value: 1 }
            }
          }
        }
      ]
    };
    const embedSpec = {
      mode: 'vega', // instruct Vega-Embed to use vega compiler.
      spec: vegaSpec,
      actions: false
    };
    // emded the visualization in the container with id vega-graph-article_id
    vg.embed(`#${this.props.graphid}`, embedSpec); // Callback receiving View instance and parsed Vega spec
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

export default EditSizeGraph;
