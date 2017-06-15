import React from 'react';

const StudentsTaughtGraph = React.createClass({
  propTypes: {
    statsData: React.PropTypes.array,
    graphWidth: React.PropTypes.number,
    graphHeight: React.PropTypes.number,
    courseStringPrefix: React.PropTypes.string
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
              data: 'courses_data',
              field: 'created_at=',
              sort: { field: 'date', op: 'min' }
            }
            ]
          },
          rangeMin: 0,
          rangeMax: this.props.graphWidth,
          round: true
        },
        {
          name: 'y',
          type: 'linear',
          domain: {
            data: 'courses_data',
            field: 'index'
          },
          rangeMin: this.props.graphHeight,
          rangeMax: 0,
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
          title: 'Date',
          ticks: 10,
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
          title: I18n.t(`${this.props.courseStringPrefix}.students_taught`),
          grid: true,
          layer: 'back',
          offset: 10
        }
      ],
      // ///////////////
      // Data Sources //
      // ///////////////
      data: [
        {
          name: 'courses_data',
          values: this.props.statsData,
          format: { type: 'json', parse: { 'created_at=': 'date', index: 'number' } }
        }
      ],
      // //////////////
      // Mark layers //
      // //////////////
      marks: [
        {
          name: 'symbol_marks',
          type: 'symbol',
          from: {
            data: 'courses_data',
            transform: [{ type: 'sort', by: '-date' }]
          },
          properties: { enter: {
            x: { scale: 'x', field: 'created_at=' },
            y: { scale: 'y', field: 'index', offset: -1 },
            size: { value: 60 },
            shape: { value: 'circle' },
            fill: { value: '#359178' },
            opacity: { value: 0.7 }
          }
          }
        },
        {
          type: 'line',
          from: {
            data: 'courses_data',
            transform: [{ type: 'sort', by: '-date' }]
          },
          properties: { enter: {
            x: { scale: 'x', field: 'created_at=' },
            y: { scale: 'y', field: 'index' },
            stroke: { value: "#575d99" },
            strokeWidth: { value: 1 }
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
    vg.embed('#StudentsTaughGraph', embedSpec); // Callback receiving View instance and parsed Vega spec
  },

  render() {
    this.renderGraph();
    return (
      <div id ="stats_graph">
        <h5> {I18n.t(`${this.props.courseStringPrefix}.students_taught`)} </h5>
        <div id= "StudentsTaughGraph" />
      </div>
    );
  }
});

export default StudentsTaughtGraph;
