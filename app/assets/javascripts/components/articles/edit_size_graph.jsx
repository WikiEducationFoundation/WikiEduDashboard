/* global vg */
import React from 'react';

const EditSizeGraph = React.createClass({
  displayName: 'EditSizeGraph',

  propTypes: {
    article: React.PropTypes.object,
    graphid: React.PropTypes.string,
    articleId: React.PropTypes.number,
    graphWidth: React.PropTypes.number,
    graphHeight: React.PropTypes.number
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
              data: 'characters_added',
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
            data: 'characters_added',
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
          title: I18n.t('articles.characters_added')
        }
      ],
      // ///////////////
      // Data Sources //
      // ///////////////
      data: [
        {
          name: 'characters_added',
          url: `/articles/article_data.json?article_id=${this.props.articleId}`,
          format: { type: 'json', parse: { date: 'date', characters: 'number' } },
          transform: [{
            type: 'filter',
            test: 'datum.date !== null && !isNaN(datum.date) && datum.characters!== null && !isNaN(datum.characters) && datum.characters > 0'
          }
          ]
        }
      ],
      // //////////////
      // Mark layers //
      // //////////////
      marks: [
        {
          name: 'line_marks',
          type: 'line',
          from: {
            data: 'characters_added',
            transform: [{ type: 'sort', by: '-date' }]
          },
          properties: { enter: {
            orient: { value: 'vertical' },
            x: { scale: 'x', field: 'date' },
            y: { scale: 'y', field: 'characters' },
            y2: { scale: 'y', value: 0 },
            stroke: { value: '#676EB4' },
            strokeWidth: { value: 1 },
            strokeOpacity: { value: 0.4 }
          }
          }
        },
        {
          name: 'circle_marks',
          type: 'symbol',
          from: {
            data: 'characters_added',
            transform: [{ type: 'sort', by: '-date' }]
          },
          properties: { enter: {
            orient: { value: 'vertical' },
            x: { scale: 'x', field: 'date' },
            y: { scale: 'y', field: 'characters' },
            y2: { scale: 'y', value: 0 },
            size: { value: 100 },
            shape: { value: 'circle' },
            fill: { value: '#359178' },
            opacity: { value: 0.7 }
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
