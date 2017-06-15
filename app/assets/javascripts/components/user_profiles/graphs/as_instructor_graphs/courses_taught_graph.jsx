import React from 'react';
const CoursesTaughtGraph = React.createClass({
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
              field: 'course_start',
              sort: { field: 'date', op: 'min' }
            },
              {
                data: 'courses_data',
                field: 'course_end',
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
          type: 'ordinal',
          domain: {
            data: 'courses_data',
            field: 'course_title'
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
          title: I18n.t(`${this.props.courseStringPrefix}.courses_taught`),
          grid: true,
          layer: 'back',
          offset: 10,
          ticks: 0,
          values: []
        }
      ],
      // ///////////////
      // Data Sources //
      // ///////////////
      data: [
        {
          name: 'courses_data',
          values: this.props.statsData,
          format: { type: 'json', parse: { course_start: 'date', course_end: 'date' } },
          transform: [{
            type: 'filter',
            test: 'datum.course_start !== null && !isNaN(datum.course_start)'
          }
          ]
        }
      ],
      // //////////////
      // Mark layers //
      // //////////////
      marks: [
        {
          name: 'text_marks',
          type: 'text',
          from: {
            data: 'courses_data',
            transform: [{ type: 'sort', by: '-date' }]
          },
          properties: { enter: {
            orient: { value: 'vertical' },
            x: { scale: 'x', field: 'course_start' },
            y: { scale: 'y', field: 'course_title', offset: -3 },
            fill: { value: '#000' },
            text: { field: 'course_title' },
            font: { value: 'Helvetica Neue' },
            fontSize: { value: 10 }
          } }
        },
        {
          name: 'rect_marks',
          type: 'rect',
          from: {
            data: 'courses_data',
            transform: [{ type: 'sort', by: '-date' }]
          },
          properties: { enter: {
            x: { scale: 'x', field: 'course_start' },
            x2: { scale: 'x', field: 'course_end' },
            y: { scale: 'y', field: 'course_title', offset: -1 },
            height: {
              value: 5
            },
            fill: {
              value: '#575d99'
            }
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
    vg.embed('#CoursesTaughtGraph', embedSpec); // Callback receiving View instance and parsed Vega spec
  },

  render() {
    this.renderGraph();
    return (
      <div id ="stats_graph">
        <h5> {I18n.t(`${this.props.courseStringPrefix}.courses_taught`)} </h5>
        <div id= "CoursesTaughtGraph" />
      </div>
    );
  }
});
export default CoursesTaughtGraph;
